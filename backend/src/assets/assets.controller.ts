// src/assets/assets.controller.ts
import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Param,
  Body,
} from '@nestjs/common';
import { AssetsService } from './assets.service';
import { Asset } from './assets.entity';

@Controller('assets')
export class AssetsController {
  constructor(private readonly assetsService: AssetsService) {}

  @Get()
  getAll(): Promise<Asset[]> {
    return this.assetsService.findAll();
  }

  @Get(':id')
  getOne(@Param('id') id: number): Promise<Asset> {
    return this.assetsService.findOne(id);
  }

  @Post()
  create(@Body() body: Partial<Asset>) {
    return this.assetsService.create(body);
  }

  @Put(':id')
  update(@Param('id') id: number, @Body() body: Partial<Asset>) {
    return this.assetsService.update(id, body);
  }

  @Delete(':id')
  remove(@Param('id') id: number) {
    return this.assetsService.remove(id);
  }
}
