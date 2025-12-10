export class SessionDTO {
  id: number;
  user_id: number;
  strategy: string;
  market_type: 'spot' | 'futures';
  result_summary?: string;
  created_at: Date;
}
