import { onUse } from '../../dnd/onUse';
import { onGive } from '../../dnd/onGive';
import { onDrop } from '../../dnd/onDrop';
import { Items } from '../../store/items';
import { fetchNui } from '../../utils/fetchNui';
import { Locale } from '../../store/locale';
import { isSlotWithItem } from '../../helpers';
import { setClipboard } from '../../utils/setClipboard';
import { useAppSelector, useAppDispatch } from '../../store';
import React from 'react';
import { Menu } from '@mantine/core';
import { closeContextMenu } from '../../store/contextMenu';
import { tokens } from '../../theme';

interface DataProps {
  action: string;
  component?: string;
  slot?: number;
  serial?: string;
  id?: number;
}

interface Button {
  label: string;
  index: number;
  group?: string;
}

interface Group {
  groupName: string | null;
  buttons: ButtonWithIndex[];
}

interface ButtonWithIndex extends Button {
  index: number;
}

const menuStyles = {
  dropdown: {
    background: tokens.bgMain,
    border: `1px solid ${tokens.borderTeal}`,
    borderRadius: 2,
    padding: 4,
  },
  item: {
    color: tokens.textSecondary,
    fontFamily: "'Rajdhani', sans-serif",
    fontSize: 13,
    fontWeight: 600,
    borderRadius: 2,
    '&:hover': {
      background: tokens.selectedBg,
      color: '#fff',
    },
  },
  label: {
    color: tokens.textMuted,
    fontFamily: "'Orbitron', sans-serif",
    fontSize: 10,
    textTransform: 'uppercase' as const,
  },
  divider: {
    borderColor: tokens.borderTeal,
  },
};

const InventoryContext: React.FC = () => {
  const contextMenu = useAppSelector((state) => state.contextMenu);
  const dispatch = useAppDispatch();
  const item = contextMenu.item;
  const coords = contextMenu.coords;
  const open = coords !== null;

  const handleClick = (data: DataProps) => {
    if (!item) return;
    dispatch(closeContextMenu());

    switch (data && data.action) {
      case 'use':
        onUse({ name: item.name, slot: item.slot });
        break;
      case 'give':
        onGive({ name: item.name, slot: item.slot });
        break;
      case 'drop':
        isSlotWithItem(item) && onDrop({ item: item, inventory: 'player' });
        break;
      case 'remove':
        fetchNui('removeComponent', { component: data?.component, slot: data?.slot });
        break;
      case 'removeAmmo':
        fetchNui('removeAmmo', item.slot);
        break;
      case 'copy':
        setClipboard(data.serial || '');
        break;
      case 'custom':
        fetchNui('useButton', { id: (data?.id || 0) + 1, slot: item.slot });
        break;
    }
  };

  const groupButtons = (buttons: any): Group[] => {
    return buttons.reduce((groups: Group[], button: Button, index: number) => {
      if (button.group) {
        const groupIndex = groups.findIndex((group) => group.groupName === button.group);
        if (groupIndex !== -1) {
          groups[groupIndex].buttons.push({ ...button, index });
        } else {
          groups.push({ groupName: button.group, buttons: [{ ...button, index }] });
        }
      } else {
        groups.push({ groupName: null, buttons: [{ ...button, index }] });
      }
      return groups;
    }, []);
  };

  if (!open || !item || !coords) return null;

  return (
    <Menu
      opened={open}
      onClose={() => dispatch(closeContextMenu())}
      position="bottom-start"
      styles={menuStyles}
      withinPortal
    >
      <Menu.Target>
        <div
          style={{
            position: 'fixed',
            left: coords.x,
            top: coords.y,
            width: 1,
            height: 1,
          }}
        />
      </Menu.Target>
      <Menu.Dropdown>
        <Menu.Item onClick={() => handleClick({ action: 'use' })}>{Locale.ui_use || 'Use'}</Menu.Item>
        <Menu.Item onClick={() => handleClick({ action: 'give' })}>{Locale.ui_give || 'Give'}</Menu.Item>
        <Menu.Item onClick={() => handleClick({ action: 'drop' })}>{Locale.ui_drop || 'Drop'}</Menu.Item>

        {item.metadata?.ammo > 0 && (
          <Menu.Item onClick={() => handleClick({ action: 'removeAmmo' })}>{Locale.ui_remove_ammo}</Menu.Item>
        )}
        {item.metadata?.serial && (
          <Menu.Item onClick={() => handleClick({ action: 'copy', serial: item.metadata?.serial })}>
            {Locale.ui_copy}
          </Menu.Item>
        )}
        {item.metadata?.components && item.metadata.components.length > 0 && (
          <>
            <Menu.Divider />
            <Menu.Label>{Locale.ui_removeattachments || 'Remove Attachments'}</Menu.Label>
            {item.metadata.components.map((component: string, index: number) => (
              <Menu.Item
                key={index}
                onClick={() => handleClick({ action: 'remove', component, slot: item.slot })}
              >
                {Items[component]?.label || component}
              </Menu.Item>
            ))}
          </>
        )}
        {((item.name && Items[item.name]?.buttons?.length) || 0) > 0 && (
          <>
            <Menu.Divider />
            {item.name &&
              groupButtons(Items[item.name]?.buttons).map((group: Group, index: number) => (
                <React.Fragment key={index}>
                  {group.groupName && <Menu.Label>{group.groupName}</Menu.Label>}
                  {group.buttons.map((button: Button) => (
                    <Menu.Item
                      key={button.index}
                      onClick={() => handleClick({ action: 'custom', id: button.index })}
                    >
                      {button.label}
                    </Menu.Item>
                  ))}
                </React.Fragment>
              ))}
          </>
        )}
      </Menu.Dropdown>
    </Menu>
  );
};

export default InventoryContext;
