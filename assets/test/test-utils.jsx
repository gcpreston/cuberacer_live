import React from 'react'
import { Provider as StoreProvider } from 'react-redux';
import { render } from '@testing-library/react'
import { diff } from 'jest-diff';
import WS from 'jest-websocket-mock';

import store from '../js/apps/room/store';
import { PhoenixSocketProvider } from '../js/contexts/socketContext';

// TODO: Need to create store between renders because this keeps the
// same stored data between tests
const AllTheProviders = ({ children }) => {
  return (
    <StoreProvider store={store}>
      <PhoenixSocketProvider>
        {children}
      </PhoenixSocketProvider>
    </StoreProvider>
  )
};

const customRender = (ui, options) =>
  render(ui, { wrapper: AllTheProviders, ...options });

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
  async replyToJoin(status, response) {
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

const WAIT_DELAY = 1000;
const TIMEOUT = Symbol('timeout');

expect.extend({
  async toReceiveEvent(server, expectedEvent, expectedPayload, options) {
    const isPhoenixWS = server instanceof PhoenixWS;
    if (!isPhoenixWS) {
      return {
        pass: this.isNot, // always fail
        message: makeInvalidWsMessage.bind(this, server, 'toReceiveMessage'),
      };
    }

    const waitDelay = options?.timeout ?? WAIT_DELAY;

    const messageOrTimeout = await Promise.race([
      server.client.nextMessage,
      new Promise((resolve) => setTimeout(() => resolve(TIMEOUT), waitDelay)),
    ]);

    if (messageOrTimeout === TIMEOUT) {
      return {
        pass: this.isNot, // always fail
        message: () =>
          this.utils.matcherHint(
            this.isNot ? '.not.toReceiveMessage' : '.toReceiveMessage',
            'WS',
            'expected'
          ) +
          '\n\n' +
          `Expected the websocket server to receive a message,\n` +
          `but it didn't receive anything in ${waitDelay}ms.`,
      };
    }
    const [_joinRef, _ref, _topic, event, payload] = messageOrTimeout;

    const pass = this.equals(event, expectedEvent) && this.equals(payload, expectedPayload);

    const message = pass
      ? () =>
          this.utils.matcherHint('.not.toReceiveEvent', 'PhoenixWS', 'expectedEvent', 'expectedPayload') +
          '\n\n' +
          `Expected the next received event and payload to not equal:\n` +
          `  ${this.utils.printExpected(expectedEvent)}\n` +
          `  ${this.utils.printExpected(expectedPayload)}\n` +
          `Received:\n` +
          `  ${this.utils.printReceived(event)}\n` +
          `  ${this.utils.printReceived(payload)}`
      : () => {
          const eventDiffString = diff(expectedEvent, event, { expand: this.expand });
          const payloadDiffString = diff(expectedPayload, payload, { expand: this.expand });

          return (
            this.utils.matcherHint('.toReceiveEvent', 'PhoenixWS', 'expectedEvent', 'expectedPayload') +
            '\n\n' +
            `Expected the next received event and payload to equal:\n` +
            `  ${this.utils.printExpected(expectedEvent)}\n` +
            `  ${this.utils.printExpected(expectedPayload)}\n` +
            `Received:\n` +
            `  ${this.utils.printReceived(event)}\n` +
            `  ${this.utils.printReceived(payload)}\n\n` +
            `Event difference:\n\n${eventDiffString}\n\n` +
            `Payload difference:\n\n${payloadDiffString}`
          );
        };

    return {
      actual: [event, payload],
      expected: [expectedEvent, expectedPayload],
      message,
      name: 'toReceiveEvent',
      pass,
    };
  }
});

// re-export everything
export * from '@testing-library/react'

// override render method
export { customRender as render }

export { PhoenixWS };
