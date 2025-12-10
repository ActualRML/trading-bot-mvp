import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
} from 'typeorm';
import { User } from '../users/users.entity';

export enum MarketType {
  SPOT = 'spot',
  FUTURES = 'futures',
}

@Entity('sessions')
export class Session {
  @PrimaryGeneratedColumn()
  id: number;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column()
  strategy: string;

  @Column({ type: 'enum', enum: MarketType })
  market_type: MarketType;

  @Column({ nullable: true })
  result_summary?: string;

  @CreateDateColumn({ name: 'created_at' })
  created_at: Date;
}
