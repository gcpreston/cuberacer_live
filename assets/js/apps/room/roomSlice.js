import { createSlice } from '@reduxjs/toolkit';
import { normalize } from 'normalizr';

import { session, round, solve, message } from './schemas';
import { actualTime, aoN } from './utils';

export const roomSlice = createSlice({
  name: 'room',
  initialState: {
    sessionId: null,
    currentUserId: null,
    chatInputFocused: false,
    entities: {
      sessions: [],
      rounds: [],
      solves: [],
      penalties: [],
      users: [],
      messages: []
    }
  },
  reducers: {
    setSession: (state, action) => {
      const { entities, result } = normalize(action.payload, session);

      state.entities = { ...state.entities, ...entities };
      state.sessionId = result;
    },
    setCurrentUserId: (state, action) => {
      state.currentUserId = action.payload;
    },
    chatInputFocused: (state) => {
      state.chatInputFocused = true;
    },
    chatInputBlurred: (state) => {
      state.chatInputFocused = false;
    },
    addRound: (state, action) => {
      const { entities, result } = normalize(action.payload, round);

      state.entities.rounds = { ...state.entities.rounds, ...entities.rounds };
      state.entities.solves = { ...state.entities.solves, ...entities.solves }; // should be empty, but still
      state.entities.sessions[state.sessionId].rounds.unshift(result);
    },
    addSolve: (state, action) => {
      const { entities, result } = normalize(action.payload, solve);

      state.entities.penalties = { ...state.entities.penalties, ...entities.penalties };
      state.entities.users = { ...state.entities.users, ...entities.users };
      state.entities.solves = { ...state.entities.solves, ...entities.solves };
      const currentRoundId = state.entities.sessions[state.sessionId].rounds[0];
      state.entities.rounds[currentRoundId].solves.push(result);
    },
    updateSolve: (state, action) => {
      const { entities } = normalize(action.payload, solve);

      state.entities.penalties = { ...state.entities.penalties, ...entities.penalties };
      state.entities.users = { ...state.entities.users, ...entities.users };
      state.entities.solves = { ...state.entities.solves, ...entities.solves };
    },
    addMessage: (state, action) => {
      const { entities, result } = normalize(action.payload, message);

      state.entities.messages = { ...state.entities.messages, ...entities.messages };
      state.entities.users = { ...state.entities.users, ...entities.users };
      state.entities.sessions[state.sessionId].room_messages.push(result);
    }
  },
});

export const {
  setSession, setCurrentUserId, chatInputFocused, chatInputBlurred, addRound, addSolve,
  updateSolve, addMessage
} = roomSlice.actions;

export const selectCurrentSession = (state) => {
  if (!state.room.sessionId) return null;
  return state.room.entities.sessions[state.room.sessionId];
};

export const selectCurrentUserId = state => state.room.currentUserId;

export const selectTimerBlocked = (state) => {
  if (!state.room.sessionId) return true;

  return state.room.chatInputFocused || Boolean(selectUserSolveForRound(
    selectCurrentUserId(state),
    selectCurrentRound(state).id
  )(state));
};

export const selectCurrentRound = (state) => {
  const session = selectCurrentSession(state);
  if (!session) return null;

  const roundId = session.rounds[0];
  return state.room.entities.rounds[roundId];
};

export const selectCurrentPuzzleName = (state) => {
  const session = selectCurrentSession(state);
  if (!session) return null;

  const puzzleTypeId = session.cube_type;
  return state.room.entities.puzzleTypes[puzzleTypeId].name;
};

export const selectUserSolveForRound = (userId, roundId) => (state) => {
  const solveId = state.room.entities.rounds[roundId].solves.find(
    // TODO: Have to do .user_id here because that's what the API gives back
    // Reason being I don't really want to preload the user just to not use that
    // data on the frontend. It makes things inconsistent though (would like to
    // have .user here). But at the same time, maybe I should preload user, because
    // we want to be able to store the entity in case it doesn't already exist
    // I guess...
    solveId => state.room.entities.solves[solveId].user_id === userId
  );
  return state.room.entities.solves[solveId];
};

export const selectRoomMessage = (roomMessageId) => (state) => {
  return state.room.entities.messages[roomMessageId];
};

export const selectUser = (userId) => (state) => {
  return state.room.entities.users[userId];
};

export const selectSolvePenalty = (solve) => (state) => {
  if (!solve) return null;
  return state.room.entities.penalties[solve.penalty];
};

/**
 * Return a selector to get all solves for a user in the session, by round.
 *
 * If a user has no solve for a round, that index will contain `undefined`.
 */
export const selectUserSolves = (userId) => (state) => {
  const session = selectCurrentSession(state);
  return session.rounds.map(roundId => selectUserSolveForRound(userId, roundId)(state));
};

/**
 * Compute all room stats for a user.
 *
 * Done in one selector so all the user's solves don't have
 * to be selected multiple times.
 */
export const selectStats = (state) => {
  const currentUserId = selectCurrentUserId(state);
  let solves = selectUserSolves(currentUserId)(state);

  // Ignore current round if user has no solve yet
  if (!solves[0]) solves = solves.splice(1);

  const times = solves.map((solve) => {
    const penalty = selectSolvePenalty(solve)(state);
    return actualTime(solve, penalty);
  });

  return {
    ao5: aoN(times, 5),
    ao12: aoN(times, 12)
  };
};

export default roomSlice.reducer;
