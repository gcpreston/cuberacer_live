import React, { useState, useEffect } from 'react';

import { useChannelWithPresence } from '../../contexts/socketContext';
import Timer from './Timer';

function currentRound(session) {
  return session.rounds[0];
}

function presenceListToUsers(presenceList) {
  return presenceList.map(data => data.user);
}

function userSolveForRound(round, user) {
  return round.solves.find(solve => solve.user_id === user.id);
}

function msToSecStr(ms) {
  return (ms / 1000).toFixed(3);
}

function displaySolve(solve) {
  if (solve === undefined) return '--';

  switch (solve.penalty.name) {
    case 'OK':
      return msToSecStr(solve.time);
    case '+2':
      return msToSecStr(solve.time + 2000) + '+';
    case 'DNF':
      return 'DNF';
  }
}

const Room = ({ roomId }) => {
  const [session, setSession] = useState(null);
  const [currentUsers, setCurrentUsers] = useState([]);
  const [chatMessage, setChatMessage] = useState('');
  const [chatInputFocused, setChatInputFocused] = useState(false);

  const [roomChannel, _roomPresence] = useChannelWithPresence(
    `room:${roomId}`,
    joinResp => setSession(joinResp),
    errorResp => console.log('error joining channel', errorResp),
    presenceList => setCurrentUsers(presenceListToUsers(presenceList))
  );

  useEffect(() => {
    if (!roomChannel) return null;

    roomChannel.on('round_created', round => {
      setSession({
        ...session,
        rounds: [
          round,
          ...session.rounds
        ]
      });
    });

    roomChannel.on('solve_created', solve => {
      setSession({
        ...session,
        rounds: [
          {
            ...session.rounds[0],
            solves: [
              ...session.rounds[0].solves,
              solve
            ]
          },
          ...session.rounds.slice(1)
        ]
      });
    });

    roomChannel.on('solve_updated', solve => {
      const otherSolves = session.rounds[0].solves.filter(s => s.id !== solve.id)
      setSession({
        ...session,
        rounds: [
          {
            ...session.rounds[0],
            solves: [
              solve,
              ...otherSolves
            ]
          },
          ...session.rounds.slice(1)
        ]
      })
    });

    roomChannel.on('message_created', roomMessage => {
      setSession({
        ...session,
        room_messages: [
          ...session.room_messages,
          roomMessage
        ]
      });
    });

    return () => {
      roomChannel.off('round_created');
      roomChannel.off('solve_created');
      roomChannel.off('solve_updated');
      roomChannel.off('message_created');
    }
  }, [roomChannel, session]);

  if (!session) return <p>Loading...</p>;

  const currentUserId = parseInt(document.querySelector('meta[name="current_user_id"]').content);

  const changePenaltyHandler = (penalty) => (
    () => roomChannel.push('change_penalty', { penalty })
  );

  const newRound = () => {
    roomChannel.push('new_round');
  };

  const newSolve = (time) => {
    roomChannel.push('new_solve', { time });
  };

  const sendMessage = () => {
    roomChannel.push('send_message', { message: chatMessage });
    setChatMessage('');
  };

  const handleChatKeyDown = (event) => {
    if (event.key === 'Enter') {
      sendMessage();
    }
  };

  return (
    <div className="flex flex-row h-full">
      <div className="flex-1 flex flex-col">
        <div className="p-4">
          <h1 className="text-xl font-bold">{session.name}</h1>
          <p className="italic mb-3">{session.cube_type.name}</p>

          <div className="my-3 mx-auto text-center">
            <div className="text-xl t_scramble">{currentRound(session).scramble}</div>
            <div className="text-6xl my-4">
              <Timer
                blocked={Boolean(chatInputFocused ||  userSolveForRound(currentRound(session), { id: currentUserId }))}
                onStop={newSolve}
              />
            </div>

            <div id="penalty-input">
              <button onClick={changePenaltyHandler('OK')}>OK</button> | <button onClick={changePenaltyHandler('+2')}>+2</button> | <button onClick={changePenaltyHandler('DNF')}>DNF</button>
            </div>

            <button
              id="new-round-button"
              className="px-4 py-2 mt-4 border border-gray-300 rounded-md shadow-sm text-sm font-medium bg-white hover:bg-gray-50"
              onClick={newRound}
            >
              New round
            </button>
          </div>
        </div>

        <div className="flex-1 overflow-auto">
          <div className="flex flex-row h-full">
            <div className="border-r">
              {/* Stats */}
              <table className="w-full">
                <thead className="bg-gray-50">
                  <tr>
                    <th scope="col" className="border-y px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Stats
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white">
                  <tr>
                    <td className="px-6 whitespace-nowrap">ao5: <span className="t_ao5">--</span></td>
                  </tr>
                  <tr>
                    <td className="px-6 whitespace-nowrap">ao12: <span className="t_ao12">--</span></td>
                  </tr>
                </tbody>
              </table>
            </div>

            <div className="flex-1 h-full overflow-auto">
              {/* Times Table */}
              <table className="w-full border-separate [border-spacing:0]">
                <thead className="bg-gray-50 sticky top-0">
                  <tr>
                    {currentUsers.map(user => (
                      <th key={user.id} scope="col" className="border-y px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        {user.username}
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody id="times-table-body" className="bg-white">
                  {session.rounds.map((round, idx) => (
                    <tr key={`round-${round.id}`} aria-label={`Round ${session.rounds.length - idx}`}>
                      {currentUsers.map(user => (
                        <td key={`round-${round.id}-solve-user-${user.id}`} className="border-b px-6 py-4 whitespace-nowrap">
                          <div className="ml-4">
                            <div className="text-sm font-medium text-gray-900">
                              {displaySolve(userSolveForRound(round, user))}
                            </div>
                          </div>
                        </td>
                      ))}
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>

      <div className="w-full h-full hidden sm:block sm:w-80">
        {/* Chat */}
        <div id="chat" className="flex flex-col border h-full w-full">
          <div className="flex-1 flex flex-col-reverse overflow-auto">
            <div id="room-messages" className="divide-y">
              {session.room_messages.map(roomMessage => (
                <div key={`room-message-${roomMessage.id}`} data-testid={`room-message-${roomMessage.id}`} className="px-2">
                  {`${roomMessage.user.username}: ${roomMessage.message}`}
                </div>
              ))}
            </div>
          </div>

          <div className="flex flex-row">
            <input
              aria-label="Chat input"
              id="chat-input"
              type="text"
              className="flex-1 border rounded-xl px-2 py-1 mx-2 my-1"
              placeholder="Chat"
              value={chatMessage}
              onChange={e => setChatMessage(e.target.value)}
              onKeyDown={handleChatKeyDown}
              onFocus={() => setChatInputFocused(true)}
              onBlur={() => setChatInputFocused(false)}
            />
            <button className="font-medium mr-2 text-cyan-600 hover:text-cyan-800" onClick={sendMessage}>Send</button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Room;
