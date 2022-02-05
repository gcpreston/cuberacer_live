import React from 'react';
import { useSelector } from 'react-redux';

import { selectCurrentSession } from '../roomSlice';
import TimesTableRow from './TimesTableRow';

const TimesTable = ({ currentUsers }) => {
  const session = useSelector(selectCurrentSession);

  return (
    <table className='w-full border-separate [border-spacing:0]'>
      <thead className='bg-gray-50 sticky top-0'>
        <tr>
          {currentUsers.map(user => (
            <th key={user.id} scope='col' className='border-y px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider'>
              {user.username}
            </th>
          ))}
        </tr>
      </thead>
      <tbody id='times-table-body' className='bg-white'>
        {session.rounds.map((roundId, idx) => (
          <TimesTableRow key={roundId} currentUsers={currentUsers} roundId={roundId} idx={idx} />
        ))}
      </tbody>
    </table>
  );
};

export default TimesTable;
