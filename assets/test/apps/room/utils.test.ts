import { actualTime, displayTime, displaySolve, aoN } from '../../../js/apps/room/utils';

describe('actualTime', () => {
  test('no solve counts as Infinity', () => {
    expect(actualTime(undefined, undefined)).toBe(Infinity);
  });

  test('OK', () => {
    expect(actualTime({ time: 4321 }, { name: 'OK' })).toBe(4321);
  });

  test('+2', () => {
    expect(actualTime({ time: 4321 }, { name: '+2'})).toBe(6321);
  });

  test('DNF', () => {
    expect(actualTime({ time: 4321 }, { name: 'DNF' })).toBe(Infinity);
  });
});

describe('displayTime', () => {
  test('no time', () => {
    expect(displayTime(undefined)).toBe('--');
  });

  test('DNF', () => {
    expect(displayTime(Infinity)).toBe('DNF');
  });

  test('displays milliseconds as seconds', () => {
    expect(displayTime(12345)).toBe('12.345');
    expect(displayTime(75981)).toBe('75.981');
  });
});

describe('displaySolve', () => {
  test('no solve', () => {
    expect(displaySolve(undefined, undefined)).toBe('--');
  });

  test('OK', () => {
    expect(displaySolve({ time: 4321 }, { name: 'OK' })).toBe('4.321');
    expect(displaySolve({ time: 76543 }, { name: 'OK' })).toBe('76.543');
  });

  test('+2', () => {
    expect(displaySolve({ time: 4321 }, { name: '+2' })).toBe('6.321+');
    expect(displaySolve({ time: 59723 }, { name: '+2' })).toBe('61.723+');
  });

  test('DNF', () => {
    expect(displaySolve({ time: 4321 }, { name: 'DNF' })).toBe('DNF');
  });
});

describe('aoN', () => {
  test('less than N times', () => {
    expect(aoN([], 12)).toBe(undefined);
    expect(aoN([1000, 2000, 4000, 12000], 5)).toBe(undefined);
  });

  test('calculates average of middle times', () => {
    expect(aoN([1100, 2000, 3000, 4600, 7200], 5)).toBe(3200);
    expect(aoN([1100, 2300, Infinity, 4600, 7200], 5)).toBe(4700);
    expect(aoN([5664, 4028, 5607, 10824, 6475, 7093, 2311, 6130, 2057, 4075], 10)).toBe(5172.875);
  });

  test('only uses the first N times', () => {
    expect(aoN([1100, 2000, 3000, 4600, 7200, Infinity, Infinity], 5)).toBe(3200);
  });

  test('multiple Infinity => DNF', () => {
    expect(aoN([1100, 2300, Infinity, 4600, Infinity], 5)).toBe(Infinity);
  });
});
