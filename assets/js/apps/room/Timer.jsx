import React, { useState, useEffect } from 'react';

const INTERVAL_MS = 10;
const READY_HOLD_TIME_MS = 500;
const PREPARING_COLOR = 'text-red-500';
const READY_COLOR = 'text-green-400';

const Timer = ({ onStop }) => {
  // null, 'preparing', 'ready', 'running'
  const [timerState, setTimerState] = useState(null);
  const [readyTimeout, setReadyTimeout] = useState(null);
  const [timerTimeout, setTimerTimeout] = useState(null);
  const [startTime, setStartTime] = useState(null);
  const [runningTime, setRunningTime] = useState(0);

  useEffect(() => {
    if (timerState === 'running') {
      setTimerTimeout(
        setTimeout(() => {
          const now = Date.now();
          const newTime = now - startTime;
          setRunningTime(newTime);
        }, INTERVAL_MS)
      );
    } else {
      clearTimeout(timerTimeout);
    }

    return () => clearTimeout(timerTimeout);
  }, [timerState, runningTime]);

  useEffect(() => {
    window.addEventListener('keydown', handleKeyDown);
    return () => {
      window.removeEventListener('keydown', handleKeyDown);
    }
  }, [timerState, runningTime]);

  useEffect(() => {
    window.addEventListener('keyup', handleKeyUp);
    return () => {
      window.removeEventListener('keyup', handleKeyUp);
    };
  }, [timerState, readyTimeout]);

  const prepare = () => {
    setReadyTimeout(
      setTimeout(() => {
        setTimerState('ready');
      }, READY_HOLD_TIME_MS)
    );
    setTimerState('preparing');
  };

  const clearPrepare = () => {
    clearTimeout(readyTimeout);
    setReadyTimeout(null);
    setTimerState(null);
  };

  const startTimer = () => {
    const now = Date.now();
    setStartTime(now);
    setTimerState('running');
  };

  const stopTimer = () => {
    setTimerState('preparing');
    clearTimeout(timerTimeout);
    setTimerTimeout(null);
    onStop(runningTime);
  };

  // Calculated fields

  const getFormattedTime = () => {
    const secondsVal = Math.floor(runningTime / 1000) % 60;
    const millisecondsVal = runningTime % 1000;

    // if timer running, only display deciseconds
    let millisecondsStr = millisecondsVal.toString().padStart(3, '0');
    if (timerState === 'running') {
      millisecondsStr = millisecondsStr.slice(0, 1);
    }

    if (runningTime < 60000) {
      return secondsVal + '.' + millisecondsStr;
    }

    const minutesVal = Math.floor(runningTime / 60000) % 60;
    const secondsStr = secondsVal.toString().padStart(2, '0');
    return minutesVal + ':' + secondsStr + '.' + millisecondsStr;
  };

  const getTimeColor = () => {
    if (timerState === 'ready') {
      return READY_COLOR;
    } else if (timerState === 'preparing') {
      return PREPARING_COLOR;
    }

    return '';
  };

  // Event handlers

  const handleKeyDown = (event) => {
    if (event.keyCode === 32) {
      // TODO: check for input focus and has current solve
      if (timerState === 'running') {
        stopTimer();
      } else if (timerState === null) {
        prepare();
      }
    }
  };

  const handleKeyUp = (event) => {
    if (event.keyCode === 32) {
      if (timerState === 'ready') {
        startTimer();
      } else if (timerState === 'preparing') {
        clearPrepare();
      }
    }
  };

  return (
    <div id="timer" onKeyDown={handleKeyDown}>
      <span id="time" className={getTimeColor()}>{getFormattedTime()}</span>
    </div>
  );
}

export default Timer;
