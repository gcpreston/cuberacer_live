import React from 'react';
import ReactDOM from 'react-dom';

import { PhoenixSocketProvider } from '../../contexts/socketContext';
import Room from './Room';

const root = document.getElementById('room-root');
const roomId = window.location.pathname.split('/').at(-1);
const currentUserId = parseInt(document.querySelector('meta[name="current_user_id"]').content);

if (root) {
  ReactDOM.render(
    <PhoenixSocketProvider>
      <Room roomId={roomId} currentUserId={currentUserId} />
    </PhoenixSocketProvider>,
    root);
}
