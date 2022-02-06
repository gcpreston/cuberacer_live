import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import { useSelector, useDispatch } from 'react-redux';

import { useChannelWithPresence } from '../../contexts/socketContext';
import {
  setSession, addRound, addSolve, updateSolve, addMessage, selectCurrentRound,
  selectCurrentPuzzleName, selectCurrentSession, selectUserSolveForRound
} from './roomSlice';
import Timer from './components/Timer';
import TimesTable from './components/TimesTable';
import Chat from './components/Chat';

function presenceListToUsers(presenceList) {
  return presenceList.map(data => data.user);
}

const Room = ({ roomId, currentUserId }) => {
  const dispatch = useDispatch();

  const [currentUsers, setCurrentUsers] = useState([]);

  const [roomChannel, _roomPresence] = useChannelWithPresence(
    `room:${roomId}`,
    joinResp => dispatch(setSession(joinResp)),
    errorResp => console.log('error joining channel', errorResp),
    presenceList => setCurrentUsers(presenceListToUsers(presenceList))
  );

  const session = useSelector(selectCurrentSession);
  const currentPuzzleName = useSelector(selectCurrentPuzzleName);
  const currentRound = useSelector(selectCurrentRound);

  useEffect(() => {
    if (!roomChannel) return null;

    roomChannel.on('round_created', round => {
      dispatch(addRound(round));
    });

    roomChannel.on('solve_created', solve => {
      dispatch(addSolve(solve));
    });

    roomChannel.on('solve_updated', solve => {
      dispatch(updateSolve(solve));
    });

    roomChannel.on('message_created', roomMessage => {
      dispatch(addMessage(roomMessage));
    });

    return () => {
      roomChannel.off('round_created');
      roomChannel.off('solve_created');
      roomChannel.off('solve_updated');
      roomChannel.off('message_created');
    }
  }, [roomChannel, session]);

  if (!session) return <p>Loading...</p>;

  const changePenaltyHandler = (penalty) => (
    () => roomChannel.push('change_penalty', { penalty })
  );

  const newRound = () => {
    roomChannel.push('new_round');
  };

  const newSolve = (time) => {
    roomChannel.push('new_solve', { time });
  };

  return (
    <div className='flex flex-row h-full'>
      <div className='flex-1 flex flex-col'>
        <div className='p-4'>
          <h1 className='text-xl font-bold'>{session.name}</h1>
          <p className='italic mb-3'>{currentPuzzleName}</p>

          <div className='my-3 mx-auto text-center'>
            <div className='text-xl t_scramble'>{currentRound.scramble}</div>
            <div className='text-6xl my-4'>
              {/* TODO: this needs to get lifted somewhre so the whole room doesn't re-render when
              this stray selector changes value */}
              <Timer
                // blocked={Boolean(chatInputFocused)}
                onStop={newSolve}
              />
            </div>

            <div id='penalty-input'>
              <button onClick={changePenaltyHandler('OK')}>OK</button> | <button onClick={changePenaltyHandler('+2')}>+2</button> | <button onClick={changePenaltyHandler('DNF')}>DNF</button>
            </div>

            <button
              id='new-round-button'
              className='px-4 py-2 mt-4 border border-gray-300 rounded-md shadow-sm text-sm font-medium bg-white hover:bg-gray-50'
              onClick={newRound}
            >
              New round
            </button>
          </div>
        </div>

        <div className='flex-1 overflow-auto'>
          <div className='flex flex-row h-full'>
            <div className='border-r'>
              {/* Stats */}
              <table className='w-full'>
                <thead className='bg-gray-50'>
                  <tr>
                    <th scope='col' className='border-y px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider'>
                      Stats
                    </th>
                  </tr>
                </thead>
                <tbody className='bg-white'>
                  <tr>
                    <td className='px-6 whitespace-nowrap'>ao5: <span className='t_ao5'>--</span></td>
                  </tr>
                  <tr>
                    <td className='px-6 whitespace-nowrap'>ao12: <span className='t_ao12'>--</span></td>
                  </tr>
                </tbody>
              </table>
            </div>

            <div className='flex-1 h-full overflow-auto'>
              {/* Times Table */}
              <TimesTable currentUsers={currentUsers} />
            </div>
          </div>
        </div>
      </div>

      <div className='w-full h-full hidden sm:block sm:w-80'>
        {/* Chat */}
        <Chat roomChannel={roomChannel} />
      </div>
    </div>
  );
};

Room.propTypes = {
  roomId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  currentUserId: PropTypes.number
};

export default Room;