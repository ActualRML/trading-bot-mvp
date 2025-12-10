export interface TransactionResult {
  hash: string;
  from?: string;
  to?: string;
  nonce?: number;
  gasPrice?: bigint | null;
}
