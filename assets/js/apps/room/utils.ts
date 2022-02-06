// DATA DEFINITIONS
//
// Time:
// A time represents a solve time in milliseconds.
// A time is an integer, or `Infinity` to denote DNF.
//
// ----------------

/**
 * Get the time of a solve after applying a penalty.
 * A `solve` of `undefined` or a DNF penalty return `Infinity`.
 */
function actualTime(solve: any, penalty: any): number {
  if (!solve) return Infinity;

  switch (penalty.name) {
    case 'OK':
      return solve.time;
    case '+2':
      return solve.time + 2000;
    case 'DNF':
      return Infinity;
  }
}

/**
 * Display a time, given in milliseconds.
 *
 * A `time` of `undefined` represents one which does not exist.
 * For example, this is used for an average of N with less than
 * N solves.
 *
 * A `time` of `Infinity` represents a DNF.
 */
function displayTime(time: number | undefined): string {
  if (time === undefined) return '--';
  if (time === Infinity) return 'DNF';
  return (time / 1000).toFixed(3);
}

/**
 * Display a solve and its penalty as a string.
 */
function displaySolve(solve: any, penalty: any): string {
  if (solve === undefined) return '--';

  switch (penalty.name) {
    case 'OK':
      return displayTime(solve.time);
    case '+2':
      return displayTime(solve.time + 2000) + '+';
    case 'DNF':
      return displayTime(Infinity);
  }
}

/**
 * Calculate the average of N for an array of times.
 *
 * Returns `undefined` if not enough times are given.
 */
function aoN(times: Array<number>, n: number): number | undefined {
  if (times.length < n) return undefined;

  times = times.splice(0, n);
  const min = Math.min(...times);
  const max = Math.max(...times);

  const minIdx = times.findIndex(time => time === min);
  times.splice(minIdx, 1);
  const maxIdx = times.findIndex(time => time === max);
  times.splice(maxIdx, 1);

  return times.reduce((a, b) => a + b) / times.length;
}

export { actualTime, displayTime, displaySolve, aoN };
