import React, { useEffect, useMemo, useRef, useState } from 'react';
import { Inventory } from '../../typings';
import InventorySlot from './InventorySlot';
import { getTotalWeight } from '../../helpers';
import { useAppSelector } from '../../store';
import { useIntersection } from '../../hooks/useIntersection';
import { Paper, Text, Progress, Stack } from '@mantine/core';
import { tokens } from '../../theme';

const PAGE_SIZE = 30;

const InventoryGrid: React.FC<{ inventory: Inventory }> = ({ inventory }) => {
  const weight = useMemo(
    () => (inventory.maxWeight !== undefined ? Math.floor(getTotalWeight(inventory.items) * 1000) / 1000 : 0),
    [inventory.maxWeight, inventory.items]
  );
  const [page, setPage] = useState(0);
  const containerRef = useRef(null);
  const { ref, entry } = useIntersection({ threshold: 0.5 });
  const isBusy = useAppSelector((state) => state.inventory.isBusy);

  useEffect(() => {
    if (entry && entry.isIntersecting) {
      setPage((prev) => ++prev);
    }
  }, [entry]);
  return (
    <Paper p="xs" style={{ border: `1px solid ${tokens.borderTeal}` }}>
      <Stack gap = {8}>
        <div className="inventory-grid-header-wrapper">
          <Text ff="'Orbitron', sans-serif" size="sm" c= "white">
            {inventory.label}
          </Text>
          {inventory.maxWeight ? (
            <Text size="sm" c="rgba(255,255,255,0.5)" ff="'Rajdhani', sans-serif">
              {weight / 1000}/{inventory.maxWeight / 1000}kg
            </Text>
          ) : null}
        </div>
          <Progress 
            value={inventory.maxWeight ? (weight / inventory.maxWeight) * 100 : 0}
            color="teal.5"
            size={3}
            styles={{ root: { backgroundColor: 'rgba(255,255,255,0.06)' }}}
          />
        <div className="inventory-grid-container" ref={containerRef}>
          {inventory.items.slice(0, (page + 1) * PAGE_SIZE).map((item, index) => (
            <InventorySlot
              key={`${inventory.type}-${inventory.id}-${item.slot}`}
              item={item}
              ref={index === (page + 1) * PAGE_SIZE - 1 ? ref : null}
              inventoryType={inventory.type}
              inventoryGroups={inventory.groups}
              inventoryId={inventory.id}
              />
          ))}
        </div>
      </Stack>
    </Paper>
  );
};

export default InventoryGrid;
