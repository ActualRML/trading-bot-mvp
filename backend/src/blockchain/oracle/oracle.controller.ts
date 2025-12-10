import { Controller, Get, Query } from '@nestjs/common';
import { OracleService } from './oracle.service';

@Controller('oracle')
export class OracleController {
  constructor(private readonly oracleService: OracleService) {}

  @Get('price')
  async getPrice(
    @Query('priceId') priceId?: string,
  ): Promise<{ price?: string; error?: string }> {
    try {
      const price: string = await this.oracleService.getPrice(priceId || '0x0');
      return { price };
    } catch (err: unknown) {
      const message: string =
        err instanceof Error ? err.message : 'Unknown error';
      return { error: message };
    }
  }
}
