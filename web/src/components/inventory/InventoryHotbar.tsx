import React, { useState } from 'react';
import { getItemUrl, isSlotWithItem } from '../../helpers';
import useNuiEvent from '../../hooks/useNuiEvent';
import { Items } from '../../store/items';
import { useAppSelector } from '../../store';
import { selectLeftInventory } from '../../store/inventory';
import { SlotWithItem } from '../../typings';
import SlideUp from '../utils/transitions/SlideUp';
import { Badge, Progress } from '@mantine/core';
import { tokens } from '../../theme';

const InventoryHotbar: React.FC = () => {
  const [hotbarVisible, setHotbarVisible] = useState(false);
  const items = useAppSelector(selectLeftInventory).items.slice(0, 5);

  const [handle, setHandle] = useState<ReturnType<typeof setTimeout>>();
  useNuiEvent('toggleHotbar', () => {
    if (hotbarVisible) {
      setHotbarVisible(false);
    } else {
      if (handle) clearTimeout(handle);
      setHotbarVisible(true);
      setHandle(setTimeout(() => setHotbarVisible(false), 3000));
    }
  });

  return (
    <SlideUp in={hotbarVisible}>
      <div className="hotbar-container">
        {items.map((item) => (
          <div
            className="hotbar-item-slot"
            key={`hotbar-${item.slot}`}
          >
            {/* Image layer — isolated so it can be filtered without affecting slot chrome */}
            <div
              style={{
                position: 'absolute',
                inset: 0,
                zIndex: 0,
                backgroundImage: `url(${item?.name ? getItemUrl(item as SlotWithItem) : 'none'})`,
                backgroundRepeat: 'no-repeat',
                backgroundPosition: 'center',
                backgroundSize: '7vh',
                imageRendering: '-webkit-optimize-contrast',
              }}
            />

            {isSlotWithItem(item) && (
              <div className="item-slot-wrapper" style={{ position: 'relative', zIndex: 1 }}>
                <div className="hotbar-slot-header-wrapper">
                  <div className="inventory-slot-number">{item.slot}</div>
                  <div className="item-slot-info-wrapper">
                    <p>
                      {item.weight > 0
                        ? item.weight >= 1000
                          ? `${(item.weight / 1000).toLocaleString('en-us', { minimumFractionDigits: 2 })}kg `
                          : `${item.weight.toLocaleString('en-us', { minimumFractionDigits: 0 })}g `
                        : ''}
                    </p>
                    {item.count ? (
                      <Badge
                        size="xs"
                        radius={2}
                        ff="'Rajdhani', sans-serif"
                        style={{
                          background: tokens.tealFaint,
                          border: `1px solid ${tokens.borderTeal}`,
                          color: '#fff',
                          fontWeight: 600,
                        }}
                      >
                        {item.count.toLocaleString('en-us')}x
                      </Badge>
                    ) : null}
                  </div>
                </div>
                <div>
                  {item?.durability !== undefined && (
                    <Progress
                      value={item.durability}
                      size={2}
                      color={item.durability < 50 ? 'red.6' : item.durability < 75 ? 'orange.5' : 'teal.5'}
                      styles={{ root: { backgroundColor: tokens.borderSubtle } }}
                    />
                  )}
                  <div className="inventory-slot-label-box">
                    <div className="inventory-slot-label-text">
                      {item.metadata?.label ? item.metadata.label : Items[item.name]?.label || item.name}
                    </div>
                  </div>
                </div>
              </div>
            )}
          </div>
        ))}
      </div>
    </SlideUp>
  );
};

export default InventoryHotbar;
