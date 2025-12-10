import { IsString, IsNumber, IsOptional } from 'class-validator';
import { Type } from 'class-transformer';

export class CreateTradeDto {
  @Type(() => Number)
  @IsNumber()
  user_id: number;

  @IsString()
  asset: string;

  @Type(() => Number)
  @IsNumber()
  amount: number;

  @Type(() => Number)
  @IsNumber()
  price: number;

  @IsString()
  side: string;

  @IsString()
  market_type: string;

  @IsOptional()
  @IsString()
  outcome?: string;
}
