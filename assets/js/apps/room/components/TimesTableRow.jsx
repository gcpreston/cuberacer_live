import React from 'react';
import { useSelector } from 'react-redux';
import { selectCurrentSession } from '../roomSlice';
import TimesTableCell from './TimesTableCell';

const TimesTableRow = ({ currentUsers, roundId, idx }) => {
  const session = useSelector(selectCurrentSession);

  return (
    <tr aria-label={`Round ${session.rounds.length - idx}`}>
      {currentUsers.map(user => (
        <TimesTableCell key={user.id} roundId={roundId} user={user} />
      ))}
    </tr>
  );
};

export default TimesTableRow;
