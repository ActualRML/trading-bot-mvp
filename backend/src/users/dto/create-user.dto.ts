import { IsEmail, IsOptional, IsString, IsNumber } from 'class-validator';

export class CreateUserDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsEmail()
  email?: string;

  @IsOptional()
  @IsString()
  role?: string;

  @IsOptional()
  @IsString()
  status?: string;

  @IsOptional()
  @IsString()
  eth_address?: string;

  @IsOptional()
  @IsNumber()
  nonce?: number;
}
