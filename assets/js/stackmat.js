import { Stackmat, PacketStatus } from 'stackmat';
import { TIMER_STATES } from './timerState';

export default class StackmatTimer {
  constructor(timerState) {
    this.timerState = timerState;
  }

  get leftHandColor() {
    if (this.timerState.state === TIMER_STATES.Ready) {
      return 'green';
    } else if (this.leftHandDown) {
      return 'red';
    } else {
      return 'gray';
    }
  }

  get rightHandColor() {
    if (this.timerState.state === TIMER_STATES.Ready) {
      return 'green';
    } else if (this.rightHandDown) {
      return 'red';
    } else {
      return 'gray';
    }
  }

  stackmatStarted() {
    this.timerState.setState(TIMER_STATES.Solving);
  }

  stackmatStopped(time) {
    this.timerState.setState(TIMER_STATES.Solved);
    window.timerHook.submitTime(time);
  }

  initStackmatListener() {
    const stackmat = new Stackmat();

    stackmat.on('packetReceived', (packet) => {
      if (packet.status === PacketStatus.RUNNING) {
        this.timerState.updateClock(packet.timeInMilliseconds);
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
      this.timerState.setState(TIMER_STATES.Ready);
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
      this.timerState.resetTime();
      this.timerState.setState(TIMER_STATES.Neutral);
    });

    this.stackmatListener = stackmat;
  }
}
