import React from 'react'
import { render } from '@testing-library/react'
import WS from 'jest-websocket-mock';

import { PhoenixSocketProvider } from '../js/contexts/socketContext';

const AllTheProviders = ({ children }) => {
  return (
    <PhoenixSocketProvider>
      {children}
    </PhoenixSocketProvider>
  )
}

const customRender = (ui, options) =>
  render(ui, { wrapper: AllTheProviders, ...options })

/**
 * A wrapper around `jest-websocket-mock`'s `WS` object for simulating Phoenix
 * server interactions for client testing purposes.
 */
class PhoenixWS {
  constructor(url, options) {
    this.client = new WS(url, options);
    this.topic = null;
    this.joinRef = null;
  }

  /**
   * Wait for a channel join request to come in. Once one does, reply with the
   * given status and response, and return the topic which the client requested
   * to join.
   *
   * @param {string} status
   * @param {object?} response
   * @returns {string}
   */
  async channelJoined(status, response) {
    while (true) {
      const [joinRef, ref, topic, event, _payload] = await this.client.nextMessage;

      if (event === 'phx_join') {
        this.topic = topic;
        this.joinRef = joinRef;
        this.client.send([joinRef, ref, topic, 'phx_reply', { status, response }]);
        return this.topic;
      }
    }
  }

  /**
   * Simulates a Phoenix event being pushed to the client. These events are not
   * replies, but rather pushes (or broadcasts) from the server.
   *
   * @param {*} event
   * @param {*} payload
   * @returns {null}
   */
  push(event, payload) {
    this.client.send([this.joinRef, null, this.topic, event, payload]);
  }
}

// re-export everything
export * from '@testing-library/react'

// override render method
export { customRender as render }

export { PhoenixWS };
