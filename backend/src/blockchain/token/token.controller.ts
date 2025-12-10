import { Controller, Get, Param } from '@nestjs/common';
import { TokenService } from './token.service';

@Controller('token')
export class TokenController {
  constructor(private readonly tokenService: TokenService) {}

  // Endpoint dinamis untuk semua token
  @Get('balance/:token')
  async getTokenBalance(@Param('token') token: string) {
    const address = this.tokenService.getWalletAddress();

    let balance: string;

    switch (token.toLowerCase()) {
      case 'btc':
        balance = await this.tokenService.getBTCBalance();
        break;
      case 'eth':
        balance = await this.tokenService.getETHBalance();
        break;
      case 'usdt':
        balance = await this.tokenService.getUSDTBalance();
        break;
      case 'sol':
        balance = await this.tokenService.getSOLBalance();
        break;
      case 'ada':
        balance = await this.tokenService.getADABalance();
        break;
      default:
        return { error: 'Token not supported' };
    }

    return { address, balance };
  }
}
