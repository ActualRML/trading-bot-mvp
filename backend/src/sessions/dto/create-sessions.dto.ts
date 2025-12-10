export class CreateSessionDTO {
  user_id: number;
  strategy: string;
  market_type: 'spot' | 'futures';
  result_summary?: string;
}
