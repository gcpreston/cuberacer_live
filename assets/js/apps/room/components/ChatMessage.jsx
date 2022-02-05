import React from 'react';
import { useSelector } from 'react-redux';

import { selectRoomMessage, selectUser } from '../roomSlice';

const ChatMessage = ({ roomMessageId }) => {
  const roomMessage = useSelector(selectRoomMessage(roomMessageId));
  const user = useSelector(selectUser(roomMessage.user));

  return (
    <div key={`room-message-${roomMessageId}`} data-testid={`room-message-${roomMessageId}`} className='px-2'>
      {`${user.username}: ${roomMessage.message}`}
    </div>
  );
};

export default ChatMessage;
