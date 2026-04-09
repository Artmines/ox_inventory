import React from 'react';
import { Button, Group, Paper, Text } from '@mantine/core';
import { useAppDispatch } from '../../store';
import { setupInventory } from '../../store/inventory';
import { tokens } from '../../theme';

const PLAYER_LEFT = {
  id: 'player',
  type: 'player',
  slots: 50,
  label: 'Bob Smith',
  weight: 3000,
  maxWeight: 5000,
  items: [
    { slot: 1, name: 'iron', weight: 3000, count: 5, metadata: { description: 'Some iron ore' } },
    { slot: 2, name: 'powersaw', weight: 0, count: 1, metadata: { durability: 75 } },
    { slot: 3, name: 'copper', weight: 100, count: 12 },
    { slot: 4, name: 'water', weight: 100, count: 1, metadata: { description: 'Generic item description' } },
    { slot: 5, name: 'water', weight: 100, count: 1 },
  ],
};

const CONFIGS: Record<string, { label: string; rightInventory: object }> = {
  crafting: {
    label: 'Crafting',
    rightInventory: {
      id: 'crafting-bench',
      type: 'crafting',
      slots: 20,
      label: 'Crafting Bench',
      weight: 0,
      maxWeight: 0,
      items: [
        {
          slot: 1,
          name: 'lockpick',
          weight: 500,
          price: 0,
          duration: 5000,
          ingredients: { iron: 5, copper: 12, powersaw: 0.1 },
          metadata: { description: 'Simple lockpick that breaks easily.' },
        },
        {
          slot: 2,
          name: 'water',
          weight: 100,
          price: 0,
          duration: 2000,
          ingredients: { iron: 2, copper: 1 },
        },
        {
          slot: 3,
          name: 'copper',
          weight: 300,
          price: 0,
          duration: 10000,
          ingredients: { iron: 10, powersaw: 0.5 },
          metadata: { schematic: true, locked: true, description: 'Requires schematic unlock.' },
        },
      ],
    },
  },
  shop: {
    label: 'Shop',
    rightInventory: {
      id: 'general-store',
      type: 'shop',
      slots: 20,
      label: 'General Store',
      weight: 0,
      maxWeight: 0,
      items: [
        { slot: 1, name: 'water', weight: 100, price: 50, count: 1 },
        { slot: 2, name: 'iron', weight: 500, price: 120, count: 1 },
        { slot: 3, name: 'copper', weight: 300, price: 80, count: 1 },
      ],
    },
  },
  stash: {
    label: 'Stash',
    rightInventory: {
      id: 'stash-1',
      type: 'stash',
      slots: 50,
      label: 'Personal Stash',
      weight: 500,
      maxWeight: 10000,
      items: [
        { slot: 1, name: 'water', weight: 100, count: 3 },
        { slot: 2, name: 'iron', weight: 500, count: 10 },
      ],
    },
  },
};

const DevMenu: React.FC = () => {
  const dispatch = useAppDispatch();

  const load = (key: string) => {
    dispatch(setupInventory({ leftInventory: PLAYER_LEFT as any, rightInventory: CONFIGS[key].rightInventory as any }));
  };

  return (
    <Paper
      style={{
        position: 'fixed',
        bottom: 12,
        right: 12,
        border: `1px solid ${tokens.borderTeal}`,
        zIndex: 9999,
        padding: 8,
      }}
    >
      <Text size="xs" c={tokens.textMuted} ff="'Orbitron', sans-serif" mb={6}>
        DEV
      </Text>
      <Group gap={6}>
        {Object.entries(CONFIGS).map(([key, cfg]) => (
          <Button
            key={key}
            size="xs"
            variant="default"
            onClick={() => load(key)}
            styles={{
              root: {
                background: tokens.bgLight,
                border: `1px solid ${tokens.borderTeal}`,
                color: '#fff',
                fontFamily: "'Rajdhani', sans-serif",
                fontSize: 12,
              },
            }}
          >
            {cfg.label}
          </Button>
        ))}
      </Group>
    </Paper>
  );
};

export default DevMenu;
