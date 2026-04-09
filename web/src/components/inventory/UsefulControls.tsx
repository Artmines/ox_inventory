import { Locale } from '../../store/locale';
import React from 'react';
import { Modal, Text, Divider, Stack, Group, Kbd } from '@mantine/core';
import { tokens } from '../../theme';

interface Props {
  infoVisible: boolean;
  setInfoVisible: React.Dispatch<React.SetStateAction<boolean>>;
}

const UsefulControls: React.FC<Props> = ({ infoVisible, setInfoVisible }) => {
  const controls = [
    { key: 'RMB', desc: Locale.ui_rmb },
    { key: 'ALT + LMB', desc: Locale.ui_alt_lmb },
    { key: 'CTRL + LMB', desc: Locale.ui_ctrl_lmb },
    { key: 'SHIFT + Drag', desc: Locale.ui_shift_drag },
    { key: 'CTRL + SHIFT + LMB', desc: Locale.ui_ctrl_shift_lmb },
  ];

  return (
    <Modal
      opened={infoVisible}
      onClose={() => setInfoVisible(false)}
      title={
        <Text ff="'Orbitron', sans-serif" size="sm" c="white">
          {Locale.ui_usefulcontrols || 'Useful Controls'}
        </Text>
      }
      centered
      styles={{
        content: {
          background: tokens.bgMain,
          border: `1px solid ${tokens.borderTeal}`,
          borderRadius: 2,
        },
        header: {
          background: tokens.bgMain,
          borderBottom: `1px solid ${tokens.borderTeal}`,
        },
        close: {
          color: tokens.textMuted,
          '&:hover': { background: tokens.selectedBg, color: '#fff' },
        },
      }}
    >
      <Stack gap="xs" pt="xs">
        {controls.map(({ key, desc }) =>
          desc ? (
            <Group key={key} justify="space-between" align="center">
              <Kbd
                style={{
                  background: tokens.bgLight,
                  border: `1px solid ${tokens.borderTeal}`,
                  color: 'var(--mantine-color-teal-4)',
                  fontFamily: "'Rajdhani', sans-serif",
                  fontSize: 11,
                  fontWeight: 700,
                }}
              >
                {key}
              </Kbd>
              <Text size="xs" ff="'Rajdhani', sans-serif" c={tokens.textSecondary}>
                {desc}
              </Text>
            </Group>
          ) : null
        )}
      </Stack>
    </Modal>
  );
};

export default UsefulControls;
