import { Module } from '@nestjs/common';
import { TokenService } from './token/token.service';
import { TokenController } from './token/token.controller';
import { OracleService } from './oracle/oracle.service';
import { MockOracleService } from './oracle/mock-oracle.service';
import { OracleController } from './oracle/oracle.controller';
import { MockOracleController } from './oracle/mock-oracle.controller';
import { SpotService } from './spot/spot.service';
import { SpotController } from './spot/spot.controller';
import { FuturesService } from './futures/futures.service';
import { FuturesController } from './futures/futures.controller';

@Module({
  providers: [
    TokenService,
    OracleService,
    MockOracleService,
    SpotService,
    FuturesService,
  ],
  controllers: [
    TokenController,
    OracleController,
    MockOracleController,
    SpotController,
    FuturesController,
  ],
  exports: [
    TokenService,
    OracleService,
    MockOracleService,
    SpotService,
    FuturesService,
  ],
})
export class BlockchainModule {}
