import React from 'react';
import ReactDOM from 'react-dom';

import Room from './Room';

const root = document.getElementById('room-root');

if (root) {
  ReactDOM.render(<Room />, root);
}
