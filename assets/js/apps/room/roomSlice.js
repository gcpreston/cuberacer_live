import { createSlice } from '@reduxjs/toolkit';
import { normalize } from 'normalizr';

import { session, round, solve, message } from './schemas';

export const roomSlice = createSlice({
  name: 'room',
  initialState: {
    sessionId: null,
    entities: {}
  },
  reducers: {
    setSession: (state, action) => {
      const { entities, result } = normalize(action.payload, session);

      state.entities = entities;
      state.sessionId = result;
    },
    addRound: (state, action) => {
      const { entities, result } = normalize(action.payload, round);

      state.entities.rounds = { ...state.entities.rounds, ...entities.rounds };
      state.entities.solves = { ...state.entities.solves, ...entities.solves }; // should be empty, but still
      state.entities.sessions[state.sessionId].rounds.unshift(result);
    },
    addSolve: (state, action) => {
      const { entities, result } = normalize(action.payload, solve);

      state.entities.solves = { ...state.entities.solves, ...entities.solves };
      state.entities.users = { ...state.entities.users, ...entities.users };
      const currentRoundId = state.entities.sessions[state.sessionId].rounds[0];
      state.entities.rounds[currentRoundId].solves.push(result);
    },
    updateSolve: (state, action) => {
      const { entities } = normalize(action.payload, solve);

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

export const { setSession, addRound, addSolve, updateSolve, addMessage } = roomSlice.actions;

export const selectCurrentSession = (state) => {
  if (!state.room.sessionId) return null;
  return state.room.entities.sessions[state.room.sessionId];
}

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

export default roomSlice.reducer;
