import React from 'react';
import { createRoot } from 'react-dom/client';
import { Provider } from 'react-redux';
import { DndProvider } from 'react-dnd';
import { TouchBackend } from 'react-dnd-touch-backend';
import { store } from './store';
import App from './App';
import './index.scss';
import { ItemNotificationsProvider } from './components/utils/ItemNotifications';
import { isEnvBrowser } from './utils/misc';
import '@mantine/core/styles.css';
import { MantineProvider } from '@mantine/core';
import { theme } from './theme';

const root = document.getElementById('root');

if (isEnvBrowser()) {
  // https://i.imgur.com/iPTAdYV.png - Night time img
  root!.style.backgroundImage = 'url("https://i.imgur.com/3pzRj9n.png")';
  root!.style.backgroundSize = 'cover';
  root!.style.backgroundRepeat = 'no-repeat';
  root!.style.backgroundPosition = 'center';
}

createRoot(root!).render(
  <React.StrictMode>
    <MantineProvider theme={theme} defaultColorScheme='dark'>
      <Provider store={store}>
        <DndProvider backend={TouchBackend} options={{ enableMouseEvents: true }}>
          <ItemNotificationsProvider>
            <App />
          </ItemNotificationsProvider>
        </DndProvider>
      </Provider>
    </MantineProvider>
  </React.StrictMode>
);
