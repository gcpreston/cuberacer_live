import { schema } from 'normalizr';

const user = new schema.Entity('users');
const puzzleType = new schema.Entity('puzzleTypes');
const penalty = new schema.Entity('penalties');
const message = new schema.Entity('messages', { user: user });
const solve = new schema.Entity('solves', { user: user, penalty: penalty });
const round = new schema.Entity('rounds', { solves: [solve] });
const session = new schema.Entity('sessions', {
  cube_type: puzzleType,
  rounds: [round],
  room_messages: [message]
});

export { user, puzzleType, message, solve, round, session };
