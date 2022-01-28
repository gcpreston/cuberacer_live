import { render, screen, waitFor } from '@testing-library/react'

import Room from '../../../js/apps/room/Room';

class WSMock {
  constructor(){}
  close(){}
  send(){}
}

beforeEach(() => {
  window.WebSocket = WSMock;
});

afterEach((done) => {
  window.WebSocket = null
  done()
});

test('reacts to solve created', () => {
  render(<Room roomId={1} />);
});
