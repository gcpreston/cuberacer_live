/**
 * Timer state, for Alpine x-data directive.
 */

const READY_HOLD_TIME_MS = 500;
const PREPARING_COLOR = 'text-red-500';
const READY_COLOR = 'text-green-400';
const SPECTATING_COLOR = 'text-gray-400'

export default () => ({
  clock: 0,
  offset: null,
  interval: null,
  readyTimeout: null,
  ready: false,
  hasCurrentSolve: false,
  spectating: false, // shadows spectating assign

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
    } else if (this.spectating) {
      return SPECTATING_COLOR;
    }

    return '';
  },

  initialize(currentSolveTime, spectating) {
    if (currentSolveTime) {
      this.presetTime(currentSolveTime);
    } else {
      this.hasCurrentSolve = false;
    }

    this.spectating = spectating;
  },

  handlePointDown() {
    if (!this.$store.inputFocused && !this.hasCurrentSolve && !this.spectating) {
      if (this.interval) {
        this.stopTime();
      } else if (!this.readyTimeout) {
        this.readyTimeout = setTimeout(() => {
          this.resetTime();
          this.ready = true;
        }, READY_HOLD_TIME_MS);
      }
    }
  },

  handlePointUp() {
    if (!this.$store.inputFocused) {
      if (this.ready) {
        this.startTime();
      } else {
        clearTimeout(this.readyTimeout);
        this.readyTimeout = null;
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
  }
});
