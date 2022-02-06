import React from 'react';
import { useSelector } from 'react-redux';

import { selectStats } from '../roomSlice';
import { displayTime } from '../utils';

const Stats = () => {
  const { ao5, ao12 } = useSelector(selectStats);

  return (
    <table className='w-full'>
      <thead className='bg-gray-50'>
        <tr>
          <th scope='col' className='border-y px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider'>
            Stats
          </th>
        </tr>
      </thead>
      <tbody className='bg-white'>
        <tr>
          <td className='px-6 whitespace-nowrap'>ao5: <span className='t_ao5'>{displayTime(ao5)}</span></td>
        </tr>
        <tr>
          <td className='px-6 whitespace-nowrap'>ao12: <span className='t_ao12'>{displayTime(ao12)}</span></td>
        </tr>
      </tbody>
    </table>
  );
};

export default Stats;
