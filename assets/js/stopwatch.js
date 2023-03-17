import { TIMER_STATES } from './timerState';

const READY_HOLD_TIME_MS = 500;

export default class Stopwatch {
  readyTimeout = null;
  interval = null;
  offset = null;

  constructor(timerState) {
    this.timerState = timerState;
  }

  setPreparing() {
    this.readyTimeout = setTimeout(() => {
      this.timerState.resetTime();
      this.timerState.setState(TIMER_STATES.Ready);
    }, READY_HOLD_TIME_MS);
    this.timerState.setState(TIMER_STATES.Preparing);
  }

  unsetPreparing() {
    clearTimeout(this.readyTimeout);
    this.readyTimeout = null;
    this.timerState.setState(TIMER_STATES.Neutral);
  }

  get isPreparing() {
    return Boolean(this.readyTimeout);
  }

  startTimer() {
    if (!this.interval) {
      this.timerState.setState(TIMER_STATES.Solving);
      this.offset = Date.now();
      this.interval = setInterval(this.updateTimer.bind(this), 10);
      window.timerHook.startSolving();
    }
  }

  updateTimer() {
    const now = Date.now();
    const delta = now - this.offset;
    this.offset = now;

    this.timerState.updateClock(this.timerState.clock + delta);
  }

  stopTimer() {
    if (this.interval) {
      this.timerState.setState(TIMER_STATES.Solved);
      clearInterval(this.interval);
      this.interval = null;
      window.timerHook.submitTime(this.timerState.clock);
    }
  }
}
