import React, { useState, useEffect } from 'react';

import { useChannel } from '../../contexts/socketContext';
import Timer from './Timer';

const Room = ({ roomId }) => {
  const [session, setSession] = useState(null);
  console.log(session);
  const roomChannel = useChannel(`room:${roomId}`, (session) => setSession(session));

  /*
  useEffect(() => {
    if (!roomChannel) return;
    ...
  }, [roomChannel]);
  */

  if (!session) return null;

  return (
    <div className="flex flex-row h-full">
      <div className="flex-1 flex flex-col">
        <div className="p-4">
          <h1 className="text-xl font-bold">{session.name}</h1>
          <p className="italic mb-3">{session.cube_type.name}</p>

          <div className="my-3 mx-auto text-center">
            {/*
            <div className={"#{scramble_text_size(current_scramble(@rounds))} t_scramble"}><%= current_scramble(@rounds) %></div>
            */}

            <div className="text-6xl my-4">
              <Timer onStop={(time) => console.log('got end time', time)} />
            </div>

            <div id="penalty-input">
              <button phx-click="change-penalty" phx-value-name="OK">OK</button> | <button phx-click="change-penalty" phx-value-name="+2">+2</button> | <button phx-click="change-penalty" phx-value-name="DNF">DNF</button>
            </div>

            <button id="new-round-button" className="px-4 py-2 mt-4 border border-gray-300 rounded-md shadow-sm text-sm font-medium bg-white hover:bg-gray-50">New round</button>
          </div>
        </div>

        <div className="flex-1 overflow-auto">
          <div className="flex flex-row h-full">
            <div className="border-r">
              {/* stats */}
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
                    <th scope="col" className="border-y px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      This person idk
                    </th>
                  </tr>
                </thead>
                <tbody id="times-table-body" className="bg-white" phx-update="prepend">
                  {/* rounds... */}
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
                <div key={`room-message-${roomMessage.id}`} className="px-2 t_room-message">
                  {`${roomMessage.user.username}: ${roomMessage.message}`}
                </div>
              ))}
            </div>
          </div>

          <div className="flex flex-row">
            <input
              id="chat-input"
              type="text"
              className="flex-1 border rounded-xl px-2 py-1 mx-2 my-1"
              placeholder="Chat"
            />
            <button className="font-medium mr-2 text-cyan-600 hover:text-cyan-800">Send</button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Room;
