import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule } from '@nestjs/config';

import { UsersModule } from './users/users.module';
import { AuthModule } from './auth/auth.module';
import { AssetsModule } from './assets/assets.module';
import { OrdersModule } from './orders/orders.module';
import { SessionsModule } from './sessions/sessions.module';
import { TradesModule } from './trades/trades.module';
import { LogsModule } from './logs/logs.module';
import { BlockchainModule } from './blockchain/blockchain.module';

import { User } from './users/users.entity';
import { Asset } from './assets/assets.entity';
import { Order } from './orders/orders.entity';
import { Session } from './sessions/sessions.entity';
import { Trade } from './trades/trade.entity';
import { Log } from './logs/log.entity';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),

    TypeOrmModule.forRootAsync({
      inject: [],
      useFactory: () => ({
        type: 'postgres',
        host: process.env.DB_HOST,
        port: Number(process.env.DB_PORT),
        username: process.env.DB_USERNAME,
        password: process.env.DB_PASSWORD,
        database: process.env.DB_DATABASE,
        entities: [User, Asset, Order, Session, Trade, Log],
        synchronize: false,
      }),
    }),

    UsersModule,
    AuthModule,
    AssetsModule,
    OrdersModule,
    SessionsModule,
    TradesModule,
    LogsModule,
    BlockchainModule,
  ],
})
export class AppModule {}
