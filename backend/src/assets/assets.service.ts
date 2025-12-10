// src/assets/assets.service.ts
import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Asset } from './assets.entity';

@Injectable()
export class AssetsService {
  constructor(
    @InjectRepository(Asset)
    private readonly assetRepo: Repository<Asset>,
  ) {}

  // Ambil semua asset
  findAll(): Promise<Asset[]> {
    return this.assetRepo.find();
  }

  // Ambil satu asset berdasarkan ID
  async findOne(id: number): Promise<Asset> {
    const asset = await this.assetRepo.findOneBy({ id });
    if (!asset) throw new NotFoundException('Asset not found');
    return asset;
  }

  // Buat asset baru
  create(data: Partial<Asset>): Promise<Asset> {
    const newAsset = this.assetRepo.create(data);
    return this.assetRepo.save(newAsset);
  }

  // Update asset
  async update(id: number, data: Partial<Asset>): Promise<Asset> {
    const asset = await this.assetRepo.findOneBy({ id });
    if (!asset) throw new NotFoundException('Asset not found');

    Object.assign(asset, data);
    return this.assetRepo.save(asset);
  }

  // Hapus asset
  async remove(id: number): Promise<{ message: string; asset: Asset }> {
    const asset = await this.assetRepo.findOneBy({ id });
    if (!asset) throw new NotFoundException('Asset not found');

    await this.assetRepo.remove(asset);

    return { message: 'Asset deleted', asset };
  }
}
