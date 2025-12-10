import { Controller, Get, Post, Query, Body } from '@nestjs/common';
import { MockOracleService } from './mock-oracle.service';

@Controller('mock-oracle')
export class MockOracleController {
  constructor(private readonly mockOracleService: MockOracleService) {}

  @Get('price')
  async getPrice(
    @Query('asset') asset: string,
  ): Promise<{ asset: string; price: string }> {
    if (!asset) throw new Error('Asset query param is required');
    const price = await this.mockOracleService.getPrice(asset);
    return { asset, price };
  }

  @Post('price')
  async setPrice(
    @Body() body: { asset: string; price: string | number },
  ): Promise<{ success: boolean }> {
    const { asset, price } = body;
    if (!asset || price === undefined)
      throw new Error('Asset and price are required');
    await this.mockOracleService.setPrice(asset, price);
    return { success: true };
  }
}
