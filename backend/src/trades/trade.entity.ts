import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity('trades')
export class Trade {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  user_id: number;

  @Column()
  asset: string;

  @Column('numeric')
  amount: number;

  @Column('numeric')
  price: number;

  @Column()
  side: string;

  @Column()
  market_type: string;

  @Column({ nullable: true })
  outcome?: string;

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  created_at: Date;
}
