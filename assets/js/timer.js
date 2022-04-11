/**
 * Timer state, for Alpine x-data directive.
 */

import { Stackmat } from 'stackmat';

const READY_HOLD_TIME_MS = 500;
const PREPARING_COLOR = 'text-red-500';
const READY_COLOR = 'text-green-400';

export default () => ({
  clock: 0,
  offset: null,
  interval: null,
  readyTimeout: null,
  ready: false,
  stackmatListener: null,
  timeEntry: 'stackmat', // 'timer', 'keyboard', 'stackmat' (?)
  hasCurrentSolve: null, // shadows assign has_current_solve?

  get formattedTime() {
    const secondsVal = Math.floor(this.clock / 1000) % 60;
    const millisecondsVal = this.clock % 1000;

    // if timer running, only display deciseconds
    let millisecondsStr = millisecondsVal.toString().padStart(3, '0');
    if (this.interval) {
      millisecondsStr = millisecondsStr.slice(0, 1);
    }

    if (this.clock < 60000) {
      return secondsVal + '.' + millisecondsStr;
    }

    const minutesVal = Math.floor(this.clock / 60000) % 60;
    const secondsStr = secondsVal.toString().padStart(2, '0');
    return minutesVal + ':' + secondsStr + '.' + millisecondsStr;
  },

  get timeColor() {
    if (this.ready) {
      return READY_COLOR;
    } else if (this.readyTimeout && !this.interval) {
      return PREPARING_COLOR;
    }

    return '';
  },

  get isRunning() {
    return Boolean(this.interval);
  },

  get isPreparing() {
    return Boolean(this.readyTimeout);
  },

  setPreparing() {
    this.readyTimeout = setTimeout(() => {
      this.resetTime();
      this.setReady();
    }, READY_HOLD_TIME_MS);
  },

  unsetPreparing() {
    clearTimeout(this.readyTimeout);
    this.readyTimeout = null;
  },

  get isReady() {
    return this.ready;
  },

  setReady() {
    this.ready = true;
  },

  handlePointDown() {
    if (!this.$store.inputFocused && !this.hasCurrentSolve) { // allow timer stuff (+ stopping time)
      if (this.isRunning) { // running
        this.stopTime();
      } else if (!this.isPreparing) { // not preparing -> start preparing
        this.setPreparing();
      }
    }
  },

  handlePointUp() {
    if (!this.$store.inputFocused) { // allow starting time
      if (this.isReady) { // ready
        this.startTime();
      } else { // let go before ready
        this.unsetPreparing();
      }
    }
  },

  startTime() {
    if (!this.interval) {
      this.ready = false;
      this.offset = Date.now();
      this.interval = setInterval(this.updateTime.bind(this), 10);
      window.timerHook.startSolving();
    }
  },

  updateTime() {
    const now = Date.now();
    const delta = now - this.offset;
    this.offset = now;

    this.clock += delta;
  },

  stopTime() {
    if (this.interval) {
      clearInterval(this.interval);
      this.interval = null;
      window.timerHook.submitTime(this.clock);
    }
  },

  resetTime() {
    if (!this.interval) {
      this.clock = 0;
    }
  },

  presetTime(clock) {
    this.clock = clock;
    this.hasCurrentSolve = true;
  },

  initStackmatListener() {
    const stackmat = new Stackmat();

    stackmat.on('ready', () => {
      this.setPreparing();
    });

    stackmat.on('unready', () => {
      this.unsetPreparing();
    });

    stackmat.on('starting', () => {
      this.setReady();
    });

    stackmat.on('started', () => {
      console.log('Timer started');
      this.startTime();
    });

    stackmat.on('stopped', (packet) => {
      console.log('Timer stopped at: ' + packet.timeAsString);
      this.stopTime();
    });

    stackmat.on('reset', () => {
      this.resetTime();
    });

    this.stackmatListener = stackmat;
    this.enableStackmat();
  },

  enableStackmat() {
    this.stackmatListener.start();
    this.timeEntry = 'stackmat';
  },

  disableStackmat() {
    this.stackmatListener.stop();
    this.timeEntry = 'timer';
  }
});
