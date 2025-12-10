import {
  IsString,
  IsNotEmpty,
  IsEthereumAddress,
  Matches,
} from 'class-validator';

export class SpotTxDto {
  @IsEthereumAddress()
  user: string;

  @IsString()
  @IsNotEmpty()
  token: string;

  @IsString()
  @IsNotEmpty()
  @Matches(/^\d+$/, { message: 'amount must be numeric string' })
  amount: string;
}
