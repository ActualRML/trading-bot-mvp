// frontend/global.d.ts
export type RequestArguments = {
  method: string;
  params?: unknown[] | object;
};

export type EthereumProvider = {
  request: (args: RequestArguments) => Promise<unknown>;
  on?: (eventName: string, handler: (...args: unknown[]) => void) => void;
  removeListener?: (eventName: string, handler: (...args: unknown[]) => void) => void;
};

declare global {
  interface Window {
    ethereum?: EthereumProvider;
  }
}

export {};
