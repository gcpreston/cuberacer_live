/**
 * Stackmat state, for Alpine x-data directive.
 */

import { Stackmat, PacketStatus } from 'stackmat';

export default () => ({


  get leftHandColor() {
    if (this.ready) {
      return 'green';
    } else if (this.leftHandDown) {
      return 'red';
    } else {
      return 'gray';
    }
  },

  get rightHandColor() {
    if (this.ready) {
      return 'green';
    } else if (this.rightHandDown) {
      return 'red';
    } else {
      return 'gray';
    }
  },

  stackmatStarted() {
    this.ready = false;
    this.stackmatRunning = true;
  },

  stackmatStopped(time) {
    this.stackmatRunning = false;
    window.timerHook.submitTime(time);
  },

  initStackmatListener() {
    const stackmat = new Stackmat();

    stackmat.on('packetReceived', (packet) => {
      if (packet.status === PacketStatus.RUNNING) {
        this.updateClock(packet.timeInMilliseconds);
      }
    });

    stackmat.on('leftHandDown', () => {
      this.leftHandDown = true;
    });

    stackmat.on('rightHandDown', () => {
      this.rightHandDown = true;
    });

    stackmat.on('leftHandUp', () => {
      this.leftHandDown = false;
    });

    stackmat.on('rightHandUp', () => {
      this.rightHandDown = false;
    });

    stackmat.on('starting', () => {
      this.setReady();
    });

    stackmat.on('started', () => {
      console.log('Timer started');
      this.stackmatStarted();
    });

    stackmat.on('stopped', (packet) => {
      console.log('Timer stopped at: ' + packet.timeAsString);
      this.stackmatStopped(packet.timeInMilliseconds);
    });

    stackmat.on('reset', () => {
      this.resetTime();
    });

    this.stackmatListener = stackmat;
  }
});
