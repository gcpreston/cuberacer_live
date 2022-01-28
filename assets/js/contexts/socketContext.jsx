import React, { createContext, useContext, useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import { Socket, Presence } from 'phoenix';

const PhoenixSocketContext = createContext({ socket: null });

const PhoenixSocketProvider = ({ children }) => {
  const [socket, setSocket] = useState();

  useEffect(() => {
    const params = { token: document.querySelector('meta[name="socket_token"]').content };
    const socket = new Socket('/socket', { params: params });
    socket.connect();
    setSocket(socket);
  }, []);

  if (!socket) return null;

  return (
    <PhoenixSocketContext.Provider value={{ socket }}>{children}</PhoenixSocketContext.Provider>
  );
};

PhoenixSocketProvider.propTypes = {
  children: PropTypes.node,
};

const useChannelWithPresence = (channelName, joinOkCallback, joinErrorCallback, syncListCallback) => {
  const [channel, setChannel] = useState();
  const [presence, setPresence] = useState();
  const { socket } = useContext(PhoenixSocketContext);

  useEffect(() => {
    const phoenixChannel = socket.channel(channelName);
    const phoenixPresence = new Presence(phoenixChannel);

    phoenixPresence.onSync(() => {
      if (syncListCallback) syncListCallback(phoenixPresence.list());
    });

    phoenixChannel.join()
      .receive('ok', (resp) => {
        setChannel(phoenixChannel);
        setPresence(phoenixPresence);

        if (joinOkCallback) joinOkCallback(resp);
      })
      .receive('error', (resp) => {
        if (joinErrorCallback) joinErrorCallback(resp);
      });

    return () => {
      phoenixChannel.leave();
    };
  }, []);

  return [channel, presence];
};

export { PhoenixSocketProvider, useChannelWithPresence };
