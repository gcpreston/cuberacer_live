/**
 * Timer state, for Alpine x-data directive.
 */

/**
 * IDEA
 * - What does LiveView need from the timer?
 *   - current clock number
 *   - timer state (preparing, ready, etc)
 * - Timer must be able to submit events to LiveView (done via global hook)
 *
 * Shared things between timer and stackmat
 * - hasCurrentSolve
 * - clock (but not interval)
 * - ready (but not its logic)
 *
 * ---------
 *
 * Ok here's how it's going to work
 * - One Alpine component which essentially controls the visuals
 * - Plain JS objects controlling logic for different timing methods
 */

const READY_HOLD_TIME_MS = 500;
const PREPARING_COLOR = 'text-red-500';
const READY_COLOR = 'text-green-400';
const TIME_ENTRY_METHODS = ['timer', 'keyboard', 'stackmat'];

export default () => ({
  clock: 0,
  offset: null,
  interval: null,
  readyTimeout: null,
  ready: false,
  stackmatListener: null,
  leftHandDown: false,
  rightHandDown: false,
  stackmatRunning: false,
  timeEntry: TIME_ENTRY_METHODS[0],
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

  get nextTimeEntryMethod() {
    const currentEntryIndex = TIME_ENTRY_METHODS.indexOf(this.timeEntry);
    const newEntryIndex = (currentEntryIndex + 1) % TIME_ENTRY_METHODS.length;
    return TIME_ENTRY_METHODS[newEntryIndex];
  },

  get timeEntryChangeIcon() {
    switch (this.nextTimeEntryMethod) {
      case 'keyboard': return 'fa-keyboard';
      case 'stackmat': return 'fa-biohazard';
      case 'timer': return 'fa-stopwatch';
    }
  },

  changeTimeEntry() {
    this.timeEntry = this.nextTimeEntryMethod;

    if (this.timeEntry === 'stackmat') {
      this.stackmatListener.start();
    } else {
      this.stackmatListener.stop();
    }
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
    if (this.timeEntry === 'timer') {
      if (!this.$store.inputFocused && !this.hasCurrentSolve) { // allow timer stuff (+ stopping time)
        if (this.isRunning) { // running
          this.stopTimer();
        } else if (!this.isPreparing) { // not preparing -> start preparing
          this.setPreparing();
        }
      }
    } else if (this.timeEntry === 'stackmat') {
      this.stackmatListener.eventManager.receivePacket({
        isValid: true,
        status: 'C',
        timeInMilliseconds: 0,
        timeAsString: '0',
        isLeftHandDown: true,
        isRightHandDown: true,
        areBothHandsDown: true
      });
    }
  },

  handlePointUp() {
    if (this.timeEntry === 'timer') {
      if (!this.$store.inputFocused) { // allow starting time
        if (this.isReady) { // ready
          this.startTimer();
        } else { // let go before ready
          this.unsetPreparing();
        }
      }
    } else if (this.timeEntry === 'stackmat') {
      this.stackmatListener.eventManager.receivePacket({
        isValid: true,
        status: 'I',
        timeInMilliseconds: 0,
        timeAsString: '0',
        isLeftHandDown: false,
        isRightHandDown: false,
        areBothHandsDown: false
      });
    }
  },

  startTimer() {
    if (!this.interval) {
      this.ready = false;
      this.offset = Date.now();
      this.interval = setInterval(this.updateTimer.bind(this), 10);
      window.timerHook.startSolving();
    }
  },

  updateTimer() {
    const now = Date.now();
    const delta = now - this.offset;
    this.offset = now;

    this.updateClock(this.clock + delta);
  },

  updateClock(newClock) {
    this.clock = newClock;
  },

  stopTimer() {
    if (this.interval) {
      clearInterval(this.interval);
      this.interval = null;
      window.timerHook.submitTime(this.clock);
    }
  },

  resetTime() {
    this.clock = 0;
  },

  presetTime(clock) {
    this.clock = clock;
    this.hasCurrentSolve = true;
  }
});
