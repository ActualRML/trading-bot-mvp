// src/assets/assets.entity.ts
import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
} from 'typeorm';

@Entity('assets')
export class Asset {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  symbol: string;

  @Column({ nullable: true })
  name?: string;

  // kasih nama kolom explicit biar sesuai DB
  @Column({ name: 'is_active', default: true })
  isActive: boolean;

  @Column({ nullable: true })
  decimals?: number;

  @CreateDateColumn({ name: 'created_at' })
  created_at: Date;
}
