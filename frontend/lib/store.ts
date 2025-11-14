import create from 'zustand'
import { initialBots } from './dummyData'

export type Bot = typeof initialBots[number]

export type State = {
  bots: Bot[]
  addBot: (b: Bot) => void
  updateBot: (id: string, patch: Partial<Bot>) => void
  removeBot: (id: string) => void
}

export const useStore = create<State>((set) => ({
  bots: initialBots,
  addBot: (b) => set((s) => ({ bots: [b, ...s.bots] })),
  updateBot: (id, patch) =>
    set((s) => ({
      bots: s.bots.map((b) => (b.id === id ? { ...b, ...patch } : b)),
    })),
  removeBot: (id) => set((s) => ({ bots: s.bots.filter((b) => b.id !== id) })),
}))
