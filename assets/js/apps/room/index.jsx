import React from 'react';
import ReactDOM from 'react-dom';
import { Provider as StoreProvider } from 'react-redux'

import { PhoenixSocketProvider } from '../../contexts/socketContext';
import store from './store';
import Room from './Room';

const root = document.getElementById('room-root');
const roomId = window.location.pathname.split('/').at(-1);

if (root) {
  ReactDOM.render(
    <StoreProvider store={store}>
      <PhoenixSocketProvider>
        <Room roomId={roomId} />
      </PhoenixSocketProvider>
    </StoreProvider>,
    root
  );
}
