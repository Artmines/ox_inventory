import React, { useState } from 'react';
import { useDrop } from 'react-dnd';
import { useAppDispatch, useAppSelector } from '../../store';
import { selectItemAmount, setItemAmount } from '../../store/inventory';
import { DragSource } from '../../typings';
import { onUse } from '../../dnd/onUse';
import { onGive } from '../../dnd/onGive';
import { fetchNui } from '../../utils/fetchNui';
import { Locale } from '../../store/locale';
import UsefulControls from './UsefulControls';
import { Button, NumberInput, ActionIcon } from '@mantine/core';
import { tokens } from '../../theme';

const InventoryControl: React.FC = () => {
  const itemAmount = useAppSelector(selectItemAmount);
  const dispatch = useAppDispatch();

  const [infoVisible, setInfoVisible] = useState(false);

  const [, use] = useDrop<DragSource, void, any>(() => ({
    accept: 'SLOT',
    drop: (source) => {
      source.inventory === 'player' && onUse(source.item);
    },
  }));

  const [, give] = useDrop<DragSource, void, any>(() => ({
    accept: 'SLOT',
    drop: (source) => {
      source.inventory === 'player' && onGive(source.item);
    },
  }));

  const inputHandler = (value: number | string) => {
    const num = typeof value === 'number' ? value : parseInt(String(value)) || 0;
    dispatch(setItemAmount(Math.max(0, Math.floor(num))));
  };

  return (
    <>
      <UsefulControls infoVisible={infoVisible} setInfoVisible={setInfoVisible} />
      <div className="inventory-control">
        <div className="inventory-control-wrapper">
          <NumberInput
            value={itemAmount}
            onChange={inputHandler}
            min={0}
            clampBehavior="strict"
            styles={{
              input: {
                background: tokens.bgLight,
                border: `1px solid ${tokens.borderTeal}`,
                color: '#fff',
                fontFamily: "'Rajdhani', sans-serif",
                textAlign: 'center',
                width: 80,
              },
              controls: {
                borderColor: tokens.borderTeal,
              },
              control: {
                color: 'var(--mantine-color-teal-5)',
                '$:hover': {
                  background: tokens.borderTeal,
                  color: 'var(mantine-color-teal-4)',
                },
              },
            }}
          />
          <Button
            ref={use}
            variant="default"
            styles={{
              root: {
                background: tokens.bgLight,
                border: `1px solid ${tokens.borderTeal}`,
                color: '#fff',
                fontFamily: "'Rajdhani', sans-serif",
                width: 80,
                '&:hover': { background: `${tokens.borderTeal}` }
              }
            }}
          >
            {Locale.ui_use || 'Use'}
          </Button>
          <Button
            ref={give}
            variant="default"
            styles={{
              root: {
                background: tokens.bgLight,
                border: `1px solid ${tokens.borderTeal}`,
                color: '#fff',
                fontFamily: "'Rajdhani', sans-serif",
                width: 80,
                '&:hover': { background: `${tokens.borderTeal}` }
              }
            }}
          >
            {Locale.ui_give || 'Give'}
          </Button>
          <Button
            variant="default"
            onClick={() => fetchNui('exit')}
            styles={{
              root: {
                background: tokens.bgLight,
                border: `1px solid ${tokens.borderTeal}`,
                color: '#fff',
                fontFamily: "'Rajdhani', sans-serif",
                width: 80,
                '&:hover': { background: `${tokens.borderTeal}` }
              }
            }}
          >
            {Locale.ui_close || 'Close'}
          </Button>
        </div>
      </div>
      
      <ActionIcon
        variant="subtle"
        color="teal"
        className="useful-controls-button"
        onClick={() => setInfoVisible(true)}
        size="lg"
      >
        <svg xmlns="http://www.w3.org/2000/svg" height="1.2em" viewBox="0 0 524 524">
          <path d="M256 512A256 256 0 1 0 256 0a256 256 0 1 0 0 512zM216 336h24V272H216c-13.3 0-24-10.7-24-24s10.7-24 24-24h48c13.3 0 24 10.7 24 24v88h8c13.3 0 24 10.7 24 24s-10.7 24-24 24H216c-13.3 0-24-10.7-24-24s10.7-24 24-24zm40-208a32 32 0 1 1 0 64 32 32 0 1 1 0-64z" />
        </svg>
      </ActionIcon>
    </>
  );
};

export default InventoryControl;
