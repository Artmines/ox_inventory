import React, { useState } from 'react';
import { Paper, Text, TextInput, ScrollArea, Stack, Group, Divider, Button, Badge } from '@mantine/core';
// Group still used for ingredient rows and recipe list items
import { useAppDispatch, useAppSelector } from '../../store';
import { selectLeftInventory } from '../../store/inventory';
import { Inventory, SlotWithItem } from '../../typings';
import { Items } from '../../store/items';
import { canCraftItem, getItemUrl, isSlotWithItem } from '../../helpers';
import { craftItem } from '../../thunks/craftItem';
import { tokens } from '../../theme';

const CraftingUI: React.FC<{ inventory: Inventory }> = ({ inventory }) => {
  const [search, setSearch] = useState('');
  const [selected, setSelected] = useState<SlotWithItem | null>(null);
  const leftInventory = useAppSelector(selectLeftInventory);
  const isBusy = useAppSelector((state) => state.inventory.isBusy);
  const dispatch = useAppDispatch();

  const recipes = inventory.items.filter(isSlotWithItem) as SlotWithItem[];

  const filtered = recipes.filter((item) => {
    const label = Items[item.name]?.label || item.name;
    return search === '' || label.toLowerCase().includes(search.toLowerCase());
  });

  const isSelectedLocked = selected?.metadata?.locked === true;
  const canCraft = selected ? !isSelectedLocked && canCraftItem(selected, 'crafting') : false;

  const handleCraft = () => {
    if (!selected || !canCraft || isBusy) return;
    const emptySlot = leftInventory.items.find((s) => !s.name);
    if (!emptySlot) return;
    dispatch(
      craftItem({
        fromSlot: selected.slot,
        fromType: 'crafting',
        toSlot: emptySlot.slot,
        toType: 'player',
        count: 1,
      })
    );
  };

  return (
    <Paper
      p="sm"
      className="crafting-ui-wrapper"
      style={{
        border: `1px solid ${tokens.borderTeal}`,
        display: 'flex',
        flexDirection: 'column',
      }}
    >
      <Text ff="'Orbitron', sans-serif" size="sm" c="white" mb="xs">
        {inventory.label || 'Crafting'}
      </Text>
      <Divider color={tokens.borderTeal} mb="xs" />

      <div style={{ flex: 1, minHeight: 0, display: 'flex', flexDirection: 'row', gap: 8, overflow: 'hidden' }}>
        {/* Recipe List */}
        <Stack style={{ width: 180, flexShrink: 0 }} gap="xs">
          <TextInput
            placeholder="Search recipes..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            size="xs"
            styles={{
              input: {
                background: tokens.bgLight,
                border: `1px solid ${tokens.borderTeal}`,
                color: '#fff',
                fontFamily: "'Rajdhani', sans-serif",
                '&::placeholder': { color: tokens.textMuted },
              },
            }}
          />
          <ScrollArea style={{ flex: 1 }}>
            <Stack gap={4}>
              {filtered.map((item) => {
                const label = Items[item.name]?.label || item.name;
                const craftable = canCraftItem(item, 'crafting');
                const isLocked = item.metadata?.locked === true;
                const isSchematic = item.metadata?.schematic === true;
                const isSelected = selected?.slot === item.slot;
                return (
                  <Group
                    key={item.slot}
                    gap="xs"
                    p="xs"
                    onClick={() => setSelected(item)}
                    style={{
                      cursor: 'pointer',
                      borderRadius: 2,
                      opacity: isLocked ? 0.5 : 1,
                      border: isSelected
                        ? `1px solid ${tokens.borderTealHover}`
                        : isLocked
                        ? `1px solid rgba(255,100,100,0.2)`
                        : `1px solid ${tokens.borderSubtle}`,
                      background: isSelected ? 'rgba(32,134,146,0.12)' : 'rgba(255,255,255,0.02)',
                      transition: 'all 150ms ease',
                    }}
                  >
                    <div style={{ position: 'relative', flexShrink: 0 }}>
                      <img
                        src={getItemUrl(item)}
                        alt={label}
                        style={{ width: 28, height: 28, objectFit: 'contain', imageRendering: '-webkit-optimize-contrast', filter: isLocked ? 'grayscale(100%)' : undefined }}
                      />
                      {isLocked && (
                        <div style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 448 512" fill="rgba(255,100,100,0.9)">
                            <path d="M144 144v48H304V144c0-44.2-35.8-80-80-80s-80 35.8-80 80zM80 192V144C80 64.5 144.5 0 224 0s144 64.5 144 144v48h16c35.3 0 64 28.7 64 64V448c0 35.3-28.7 64-64 64H64c-35.3 0-64-28.7-64-64V256c0-35.3 28.7-64 64-64H80z"/>
                          </svg>
                        </div>
                      )}
                    </div>
                    <Stack gap={2} style={{ flex: 1, minWidth: 0 }}>
                      <Text size="xs" ff="'Orbitron', sans-serif" c={isLocked ? tokens.textMuted : 'white'} style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                        {label}
                      </Text>
                      {isLocked ? (
                        <Badge size="xs" radius={2} color="red" variant="light" ff="'Rajdhani', sans-serif">
                          Locked
                        </Badge>
                      ) : isSchematic && craftable ? (
                        <Badge size="xs" radius={2} color="teal" variant="light" ff="'Rajdhani', sans-serif">
                          Unlocked
                        </Badge>
                      ) : craftable ? (
                        <Badge size="xs" radius={2} color="teal" variant="light" ff="'Rajdhani', sans-serif">
                          Craftable
                        </Badge>
                      ) : null}
                    </Stack>
                  </Group>
                );
              })}
              {filtered.length === 0 && (
                <Text size="xs" c={tokens.textMuted} ff="'Rajdhani', sans-serif" ta="center" mt="md">
                  No recipes found
                </Text>
              )}
            </Stack>
          </ScrollArea>
        </Stack>

        <Divider orientation="vertical" color={tokens.borderTeal} />

        {/* Recipe Detail */}
        <div style={{ flex: 1, overflow: 'hidden', display: 'flex', flexDirection: 'column', gap: 8 }}>
          {/* Scrollable content */}
          <div style={{ flex: 1, overflow: 'auto' }}>
            {selected ? (
              <Stack gap={8}>
                <Group gap="sm" align="center">
                  <img
                    src={getItemUrl(selected)}
                    alt={Items[selected.name]?.label || selected.name}
                    style={{ width: 56, height: 56, objectFit: 'contain', imageRendering: '-webkit-optimize-contrast' }}
                  />
                  <Stack gap={2}>
                    <Text ff="'Orbitron', sans-serif" size="sm" c="white" fw={600}>
                      {Items[selected.name]?.label || selected.name}
                    </Text>
                    {selected.duration !== undefined && (
                      <Text size="xs" ff="'Rajdhani', sans-serif" c={tokens.textMuted}>
                        Duration: {selected.duration / 1000}s
                      </Text>
                    )}
                  </Stack>
                </Group>

                <Divider color={tokens.borderSubtle} />

                <Text size="xs" ff="'Orbitron', sans-serif" c={tokens.textMuted} tt="uppercase">
                  Ingredients
                </Text>
                <Stack gap={6}>
                  {selected.ingredients &&
                    Object.entries(selected.ingredients)
                      .sort((a, b) => b[1] - a[1])
                      .map(([name, count]) => {
                        const has = leftInventory.items.some(
                          (s) => isSlotWithItem(s) && s.name === name && (count < 1 || (s.count ?? 0) >= count)
                        );
                        return (
                          <Group key={name} gap="xs" align="center">
                            <img
                              src={getItemUrl(name)}
                              alt={name}
                              style={{ width: 28, height: 28, objectFit: 'contain', imageRendering: '-webkit-optimize-contrast' }}
                            />
                            <Text size="xs" ff="'Rajdhani', sans-serif" c={has ? tokens.textSecondary : 'red.4'}>
                              {count >= 1
                                ? `${count}x ${Items[name]?.label || name}`
                                : `${count * 100}% ${Items[name]?.label || name}`}
                            </Text>
                          </Group>
                        );
                      })}
                </Stack>
              </Stack>
            ) : (
              <Text size="sm" c={tokens.textMuted} ff="'Rajdhani', sans-serif" ta="center" mt="xl">
                Select a recipe
              </Text>
            )}
          </div>

          {/* Button always pinned at bottom */}
          <Button
            fullWidth
            color={isSelectedLocked ? 'red' : 'teal'}
            variant={canCraft ? 'filled' : 'default'}
            disabled={!selected || !canCraft || isBusy}
            onClick={handleCraft}
            ff="'Rajdhani', sans-serif"
            tt="uppercase"
            fw={700}
            styles={{
              root: {
                letterSpacing: '0.08em',
                flexShrink: 0,
                border: `1px solid ${isSelectedLocked ? 'rgba(255,100,100,0.3)' : canCraft ? tokens.borderTealHover : tokens.borderSubtle}`,
              },
            }}
          >
            {isSelectedLocked ? 'Locked' : 'Craft'}
          </Button>
        </div>
      </div>
    </Paper>
  );
};

export default CraftingUI;
