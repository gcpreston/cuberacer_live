import React from 'react';
import WS from 'jest-websocket-mock';
import { PhoenixWS, render, screen } from '../../test-utils';

import Room from '../../../js/apps/room/Room';

WEBSOCKET_URL = 'ws://localhost/socket/websocket';

describe('<Room />', () => {
  let server;

  beforeEach(() => {
    server = new PhoenixWS(WEBSOCKET_URL, { jsonProtocol: true });
  });

  afterEach(() => {
    WS.clean()
  });

  test('renders interface and initial data', async () => {
    render(<Room roomId={123} />);

    expect(screen.getByText('Loading...')).toBeInTheDocument();
    expect(screen.queryByRole('heading')).not.toBeInTheDocument();

    await server.connected;

    const topic = await server.channelJoined('ok', {
      name: 'test room',
      cube_type: { name: '2x2' },
      room_messages: [
        { id: 82, message: 'test message', user: { id: 2, email: 'testuser1@example.com', username: 'testuser1' } },
        { id: 83, message: 'hi', user: { id: 6, email: 'testuser2@example.com', username: 'testuser2' } }
      ],
      rounds: [
        {
          id: 181,
          scramble: "R U' R F R2 F R2 F' R U'",
          solves: [
            { id: 110, time: 1421, user_id: 2, penalty: { name: '+2' } },
            { id: 111, time: 2345, user_id: 6, penalty: { name: 'DNF' } }
          ]
        }, {
          id: 180,
          scramble: "U F U' R' F' U2 F' R' U' F'",
          solves: []
        }, {
          id: 179,
          scramble: "U' R' F2 U2 R' F' U2 F R' F",
          solves: [{ id: 109, time: 5456, user_id: 2, penalty: { name: 'OK' } }]
        }
      ]
    });
    server.push('presence_state', {
      '2': {
        metas: [{ phx_ref: 'Fs8ZgGa7d_G2xAIi' }],
        user: { id: 2, email: 'testuser1@example.com', username: 'testuser1' }
      }
    });

    expect(topic).toBe('room:123');

    // Interface
    expect(await screen.findByRole('heading')).toHaveTextContent('test room');
    expect(screen.queryByText('Loading...')).not.toBeInTheDocument();
    expect(screen.getByText('2x2')).toBeInTheDocument();
    expect(screen.getByText("R U' R F R2 F R2 F' R U'")).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'OK' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: '+2' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'DNF' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'New round' })).toBeInTheDocument();
    expect(screen.getByRole('columnheader', { name: 'Stats' })).toBeInTheDocument();
    expect(screen.getByRole('cell', { name: 'ao5: --' })).toBeInTheDocument();
    expect(screen.getByRole('cell', { name: 'ao12: --' })).toBeInTheDocument();
    expect(screen.getByRole('textbox', { name: 'Chat input' })).toBeInTheDocument();

    // Chat
    const msgs = screen.getAllByTestId('room-message')
    expect(msgs.length).toBe(2);
    expect(msgs[0]).toHaveTextContent('testuser1: test message');
    expect(msgs[1]).toHaveTextContent('testuser2: hi');

    // Times table
    expect(await screen.findByRole('columnheader', { name: 'testuser1' })).toBeInTheDocument();
    expect(screen.queryByRole('columnheader', { name: 'testuser2' })).not.toBeInTheDocument();
    const rounds = screen.getAllByRole('row', { name: /Round \d+/ });
    expect(rounds.length).toBe(3);
    expect(rounds[0]).toHaveAccessibleName('Round 3');
    expect(rounds[1]).toHaveAccessibleName('Round 2');
    expect(rounds[2]).toHaveAccessibleName('Round 1');

    expect(screen.getByRole('cell', { name: '3.421+' })).toBeInTheDocument();
    expect(screen.getByRole('cell', { name: '--' })).toBeInTheDocument();
    expect(screen.getByRole('cell', { name: '5.456' })).toBeInTheDocument();
    expect(screen.queryByRole('cell', { name: '4.345' })).not.toBeInTheDocument();
  });
});
