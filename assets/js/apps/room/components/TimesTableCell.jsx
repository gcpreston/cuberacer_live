import React from 'react';
import { useSelector } from 'react-redux';
import { selectUserSolveForRound } from '../roomSlice';

function msToSecStr(ms) {
  return (ms / 1000).toFixed(3);
}

function displaySolve(solve) {
  if (solve === undefined) return '--';

  switch (solve.penalty.name) {
    case 'OK':
      return msToSecStr(solve.time);
    case '+2':
      return msToSecStr(solve.time + 2000) + '+';
    case 'DNF':
      return 'DNF';
  }
}

const TimesTableCell = ({ roundId, user }) => {
  const userSolveForRound = useSelector(selectUserSolveForRound(user.id, roundId));

  return (
    <td key={`round-${roundId}-solve-user-${user.id}`} className='border-b px-6 py-4 whitespace-nowrap'>
      <div className='ml-4'>
        <div className='text-sm font-medium text-gray-900'>
          {displaySolve(userSolveForRound)}
        </div>
      </div>
    </td>
  );
};

export default TimesTableCell;
