// trades.controller.ts
import {
  Controller,
  Post,
  Get,
  Delete,
  Param,
  Query,
  Body,
} from '@nestjs/common';
import { TradesService } from './trades.service';
import { CreateTradeDto } from './dto/create-trade.dto';

@Controller('trades')
export class TradesController {
  constructor(private readonly service: TradesService) {}

  @Post()
  create(@Body() body: CreateTradeDto) {
    return this.service.create(body);
  }

  @Get()
  findAll(
    @Query('asset') asset?: string,
    @Query('side') side?: string,
    @Query('market_type') market_type?: string,
  ) {
    return this.service.findAll({ asset, side, market_type });
  }

  @Get('user/:user_id')
  findByUser(@Param('user_id') user_id: number) {
    return this.service.findByUser(Number(user_id));
  }

  @Get(':id')
  findOne(@Param('id') id: number) {
    return this.service.findOne(Number(id));
  }

  @Delete(':id')
  delete(@Param('id') id: number) {
    return this.service.delete(Number(id));
  }
}
