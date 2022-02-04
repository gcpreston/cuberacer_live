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
      selectCurrentRound(state).solves.push(result);
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

export const selectCurrentRound = (state) => {
  const roundId = state.entities.sessions[state.sessionId].rounds[0];
  return state.entities.rounds[roundId];
};

export default roomSlice.reducer;
