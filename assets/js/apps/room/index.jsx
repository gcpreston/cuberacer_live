import React from 'react';
import ReactDOM from 'react-dom';

import { PhoenixSocketProvider } from '../../contexts/socketContext';
import Room from './Room';

const root = document.getElementById('room-root');
const roomId = window.location.pathname.split('/').at(-1);

if (root) {
  ReactDOM.render(
    <PhoenixSocketProvider>
      <Room roomId={roomId} />
    </PhoenixSocketProvider>,
    root);
}
