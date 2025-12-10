import { Controller, Get, Param } from '@nestjs/common';
import { SpotService } from './spot.service';
import { ethers } from 'ethers';

@Controller('spot')
export class SpotController {
  constructor(private readonly spotService: SpotService) {}

  @Get('vaults/:user')
  async getVaults(@Param('user') user: string) {
    const raw = String(user ?? '');
    const cleanUser = raw.trim();

    // Kalau address user tidak valid, balikin zero balances biar FE tetap bisa render
    if (!ethers.isAddress(cleanUser)) {
      console.warn(
        `[spot] Invalid user address received: "${raw}". Returning zeroed balances.`,
      );

      const defaultTokens = ['BTC', 'ETH', 'USDT', 'SOL', 'ADA'];
      const spot = defaultTokens.map((asset) => ({
        asset,
        balance: '0',
        locked: '0',
      }));

      return { spot };
    }

    const spot = await this.spotService.getSpotVault(cleanUser);
    return { spot };
  }
}
