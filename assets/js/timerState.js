import Stopwatch from './stopwatch';
import StackmatTimer from './stackmat';

const PREPARING_COLOR = 'text-red-500';
const READY_COLOR = 'text-green-400';

const TIME_ENTRY_METHODS = ['Stopwatch', 'Keyboard', 'Stackmat'];

export const TIMER_STATES = {
  Neutral: 'Neutral',
  Preparing: 'Preparing',
  Ready: 'Ready',
  Solving: 'Solving',
  Solved: 'Solved'
}

export default () => ({
  timeEntry: TIME_ENTRY_METHODS[0],
  state: TIMER_STATES.Neutral,
  clock: 0,
  timers:{
    stopwatch: null,
    stackmat: null
  },

  init() {
    this.timers.stopwatch = new Stopwatch(this);
    this.timers.stackmat = new StackmatTimer(this);
  },

  get formattedTime() {
    const secondsVal = Math.floor(this.clock / 1000) % 60;
    const millisecondsVal = this.clock % 1000;

    // if timer running, only display deciseconds
    let millisecondsStr = millisecondsVal.toString().padStart(3, '0');
    if (this.state === TIMER_STATES.Solving) {
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
    switch (this.state) {
      case TIMER_STATES.Neutral:
        return '';
      case TIMER_STATES.Preparing:
        return PREPARING_COLOR;
      case TIMER_STATES.Ready:
        return READY_COLOR;
      case TIMER_STATES.Solving:
        return '';
      case TIMER_STATES.Solves:
        return '';
    }
  },

  get nextTimeEntryMethod() {
    const currentEntryIndex = TIME_ENTRY_METHODS.indexOf(this.timeEntry);
    const newEntryIndex = (currentEntryIndex + 1) % TIME_ENTRY_METHODS.length;
    return TIME_ENTRY_METHODS[newEntryIndex];
  },

  get timeEntryChangeIcon() {
    switch (this.nextTimeEntryMethod) {
      case 'Keyboard': return 'fa-keyboard';
      case 'Stackmat': return 'fa-biohazard';
      case 'Stopwatch': return 'fa-stopwatch';
    }
  },

  changeTimeEntry() {
    this.timeEntry = this.nextTimeEntryMethod;

    /*
    if (this.timeEntry === 'Stackmat') {
      this.stackmatListener.start();
    } else {
      this.stackmatListener.stop();
    }
    */
  },

  setState(state) {
    this.state = state;
  },

  handlePointDown() {
    if (this.timeEntry === 'Stopwatch') {
      if (!this.$store.inputFocused && !this.hasCurrentSolve) { // allow timer stuff (+ stopping time)
        if (this.state === TIMER_STATES.Solving) {
          this.timers.stopwatch.stopTimer();
        } else if (!this.timers.stopwatch.isPreparing) { // not preparing -> start preparing
          this.timers.stopwatch.setPreparing();
        }
      }
    }
  },

  handlePointUp() {
    if (this.timeEntry === 'Stopwatch') {
      if (!this.$store.inputFocused) { // allow starting time
        if (this.state === TIMER_STATES.Ready) { // ready
          this.timers.stopwatch.startTimer();
        } else { // let go before ready
          this.timers.stopwatch.unsetPreparing();
        }
      }
    }
  },

  updateClock(newClock) {
    this.clock = newClock;
  },

  resetTime() {
    this.clock = 0;
  },

  presetTime(clock) {
    this.clock = clock;
    this.hasCurrentSolve = true;
    this.state = TIMER_STATES.Solved;
  }
});
