import { createTheme, MantineColorsTuple } from '@mantine/core';

export const tokens = {
    // Backgrounds
    bgMain:        '#121025',
    bgLight:       '#1c1a30',
    bgDark:        '#0a0914',
    // Teal borders
    borderTeal:       'rgba(32,134,146,0.2)',
    borderTealHover:  'rgba(32,134,146,0.5)',
    borderSubtle:     'rgba(255,255,255,0.06)',
    // Teal fills
    tealFaint:     'rgba(32,134,146,0.25)',
    selectedBg:    'rgba(32,134,146,0.12)',
    // Text
    textPrimary:   '#ffffff',
    textSecondary: 'rgba(255,255,255,0.7)',
    textMuted:     'rgba(255,255,255,0.35)',
    // Error / locked
    errorFaint:    'rgba(255,100,100,0.2)',
    errorText:     'rgba(255,100,100,0.9)',
  } as const;

const teal: MantineColorsTuple = [
    '#e6f7f8',
    '#cceff1',
    '#99dfe3',
    '#66cfd5',
    '#33bfc7',
    '#208692', // [5] primary
    '#1a6b75',
    '#135058',
    '#0d363b',
    '#071b1e',
];

export const theme = createTheme({
    primaryColor: 'teal',
    colors: { teal },

    fontFamily: "'Rajdhani', sans-serif",
    headings: {
        fontFamily: "'Orbitron', sans-serif",
    },

    defaultRadius: 2,
    black: '#121025',
    white: '#ffffff',
    components: {
        Paper: {
            defaultProps: {
                bg: '#121025',
            },
        },
    ScrollArea: {
        styles: {
            scrollbar: {
                '&[data-orientation="vertical]"': { width: 4 },
            },
            thumb: {
                backgroundColor: 'rgba(32,134,146,0.3)',
                '&:hover': { backgroundColor: '#208692'}
                },
            },
        },
    },
}); 