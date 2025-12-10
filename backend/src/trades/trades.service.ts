// trades.service.ts
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Trade } from './trade.entity';
import { CreateTradeDto } from './dto/create-trade.dto';

@Injectable()
export class TradesService {
  constructor(
    @InjectRepository(Trade)
    private repo: Repository<Trade>,
  ) {}

  create(dto: CreateTradeDto) {
    const trade = this.repo.create(dto);
    return this.repo.save(trade);
  }

  findAll(filters: { asset?: string; side?: string; market_type?: string }) {
    const qb = this.repo.createQueryBuilder('t');

    if (filters.asset)
      qb.andWhere('t.asset = :asset', { asset: filters.asset });
    if (filters.side) qb.andWhere('t.side = :side', { side: filters.side });
    if (filters.market_type)
      qb.andWhere('t.market_type = :market_type', {
        market_type: filters.market_type,
      });

    return qb.orderBy('t.created_at', 'DESC').getMany();
  }

  findByUser(user_id: number) {
    return this.repo.find({
      where: { user_id },
      order: { created_at: 'DESC' },
    });
  }

  findOne(id: number) {
    return this.repo.findOne({ where: { id } });
  }

  async delete(id: number) {
    await this.repo.delete(id);
    return { deleted: true };
  }
}
