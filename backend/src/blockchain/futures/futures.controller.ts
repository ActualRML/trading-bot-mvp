import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';

import { FuturesService } from './futures.service';
import {
  OpenPositionDto,
  ClosePositionDto,
} from './dto/open-close-position.dto';

@Controller('futures')
export class FuturesController {
  private readonly logger = new Logger(FuturesController.name);

  constructor(private readonly futuresService: FuturesService) {}

  private fail(message: string, err: unknown): never {
    const details =
      typeof err === 'string'
        ? err
        : err instanceof Error
          ? err.message
          : '[unknown error]';

    throw new HttpException(
      { error: message, details },
      HttpStatus.INTERNAL_SERVER_ERROR,
    );
  }

  // ================= VAULT (READ-ONLY) =================

  @Get('balance/:user/:token')
  async balance(@Param('user') user: string, @Param('token') token: string) {
    try {
      return await this.futuresService.getBalance(token, user);
    } catch (err) {
      this.logger.error('get balance failed', err);
      this.fail('Get balance failed', err);
    }
  }

  @Get('free-balance/:user/:token')
  async freeBalance(
    @Param('user') user: string,
    @Param('token') token: string,
  ) {
    try {
      return await this.futuresService.getFreeBalance(token, user);
    } catch (err) {
      this.logger.error('get free balance failed', err);
      this.fail('Get free balance failed', err);
    }
  }

  @Get('vaults/:user')
  async getVaults(@Param('user') user: string) {
    try {
      const tokenMap = {
        BTC: process.env.TOKEN_BTC,
        ETH: process.env.TOKEN_ETH,
        USDT: process.env.TOKEN_USDT,
        SOL: process.env.TOKEN_SOL,
        ADA: process.env.TOKEN_ADA,
      };

      const items = await Promise.all(
        Object.entries(tokenMap).map(async ([symbol, address]) => {
          const tokenAddress = address ?? '';
          const raw = await this.futuresService.getBalance(tokenAddress, user);

          return {
            asset: symbol,
            collateral: Number(raw),
            pnl: 0,
          };
        }),
      );

      return { futures: items };
    } catch (err) {
      this.logger.error('get vaults failed', err);
      this.fail('Get vaults failed', err);
    }
  }

  // ================= EXCHANGE =================

  @Post('open-position')
  async openPosition(@Body() body: OpenPositionDto) {
    try {
      return await this.futuresService.openPosition(
        body.asset,
        body.size,
        body.isLong,
        body.collateralToken,
        body.collateralAmount,
      );
    } catch (err) {
      this.logger.error('open position failed', err);
      this.fail('Open position failed', err);
    }
  }

  @Post('close-position')
  async closePosition(@Body() body: ClosePositionDto) {
    try {
      return await this.futuresService.closePosition(
        body.positionId,
        body.collateralToken,
        body.collateralAmount,
      );
    } catch (err) {
      this.logger.error('close position failed', err);
      this.fail('Close position failed', err);
    }
  }

  @Get('position/:positionId')
  async getPosition(@Param('positionId') positionId: string) {
    try {
      return await this.futuresService.getPosition(positionId);
    } catch (err) {
      this.logger.error('get position failed', err);
      this.fail('Get position failed', err);
    }
  }
}
