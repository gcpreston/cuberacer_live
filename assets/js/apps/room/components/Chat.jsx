import React, { useState } from 'react';
import { useSelector } from 'react-redux';

import { selectCurrentSession } from '../roomSlice';
import ChatMessage from './ChatMessage';

const Chat = ({ roomChannel }) => {
  const session = useSelector(selectCurrentSession);

  const [chatMessage, setChatMessage] = useState('');
  const [chatInputFocused, setChatInputFocused] = useState(false);

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
    <div id='chat' className='flex flex-col border h-full w-full'>
      <div className='flex-1 flex flex-col-reverse overflow-auto'>
        <div id='room-messages' className='divide-y'>
          {session.room_messages.map(roomMessageId => (
            <ChatMessage key={roomMessageId} roomMessageId={roomMessageId} />
          ))}
        </div>
      </div>

      <div className='flex flex-row'>
        <input
          aria-label='Chat input'
          id='chat-input'
          type='text'
          className='flex-1 border rounded-xl px-2 py-1 mx-2 my-1'
          placeholder='Chat'
          value={chatMessage}
          onChange={e => setChatMessage(e.target.value)}
          onKeyDown={handleChatKeyDown}
          onFocus={() => setChatInputFocused(true)}
          onBlur={() => setChatInputFocused(false)}
        />
        <button className='font-medium mr-2 text-cyan-600 hover:text-cyan-800' onClick={sendMessage}>Send</button>
      </div>
    </div>
  );
};

export default Chat;
