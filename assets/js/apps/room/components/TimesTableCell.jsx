import React from 'react';
import { useSelector } from 'react-redux';

import { selectUserSolveForRound, selectSolvePenalty } from '../roomSlice';
import { displaySolve } from '../utils';

const TimesTableCell = ({ roundId, user }) => {
  const solve = useSelector(selectUserSolveForRound(user.id, roundId));
  const penalty = useSelector(selectSolvePenalty(solve));

  return (
    <td key={`round-${roundId}-solve-user-${user.id}`} className='border-b px-6 py-4 whitespace-nowrap'>
      <div className='ml-4'>
        <div className='text-sm font-medium text-gray-900'>
          {displaySolve(solve, penalty)}
        </div>
      </div>
    </td>
  );
};

export default TimesTableCell;
