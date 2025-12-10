import { Injectable, Logger } from '@nestjs/common';
import {
  Wallet,
  Contract,
  JsonRpcProvider,
  type TransactionResponse,
  type InterfaceAbi,
  ethers,
} from 'ethers';

import FuturesVaultJson from './abis/FuturesVault.json';
import FuturesExchangeJson from './abis/FuturesExchange.json';

// ================= TYPES =================

type FuturesVaultContract = Contract & {
  balanceOf(user: string, token: string): Promise<bigint>;
  freeBalanceOf(user: string, token: string): Promise<bigint>;
  deposit(
    user: string,
    token: string,
    amount: string,
  ): Promise<TransactionResponse>;
  withdraw(
    user: string,
    token: string,
    amount: string,
  ): Promise<TransactionResponse>;
};

type FuturesExchangeContract = Contract & {
  openPosition(
    asset: string,
    size: string,
    isLong: boolean,
    collateralToken: string,
    collateralAmount: string,
  ): Promise<string>;
  closePosition(
    positionId: string,
    collateralToken: string,
    collateralAmount: string,
  ): Promise<TransactionResponse>;
  getPosition(positionId: string): Promise<unknown>;
};

@Injectable()
export class FuturesService {
  private readonly logger = new Logger(FuturesService.name);
  private readonly provider: JsonRpcProvider;
  private readonly wallet: Wallet;

  readonly vault: FuturesVaultContract;
  readonly exchange: FuturesExchangeContract;

  // =========================================
  // TOKEN MAPPING (SAME AS SPOT SERVICE)
  // =========================================
  private readonly tokenAddresses: Record<string, string> = {
    BTC: String(process.env.TOKEN_BTC ?? '').trim(),
    ETH: String(process.env.TOKEN_ETH ?? '').trim(),
    USDT: String(process.env.TOKEN_USDT ?? '').trim(),
    SOL: String(process.env.TOKEN_SOL ?? '').trim(),
    ADA: String(process.env.TOKEN_ADA ?? '').trim(),
  };

  constructor() {
    const rpcUrl = String(process.env.RPC_URL ?? '').trim();
    if (!rpcUrl) throw new Error('RPC_URL not set');
    this.provider = new JsonRpcProvider(rpcUrl, {
      name: 'hardhat',
      chainId: 31337,
    });

    const privateKey = String(process.env.PRIVATE_KEY ?? '').trim();
    if (!privateKey.startsWith('0x')) throw new Error('Invalid PRIVATE_KEY');
    this.wallet = new Wallet(privateKey, this.provider);

    const vaultAddress = String(process.env.FUTURES_VAULT ?? '').trim();
    const exchangeAddress = String(process.env.FUTURES_EXCHANGE ?? '').trim();

    if (!ethers.isAddress(vaultAddress) || !ethers.isAddress(exchangeAddress)) {
      throw new Error('Futures contract addresses must be valid hex');
    }

    this.vault = new Contract(
      vaultAddress,
      FuturesVaultJson as InterfaceAbi,
      this.wallet,
    ) as FuturesVaultContract;

    this.exchange = new Contract(
      exchangeAddress,
      FuturesExchangeJson as InterfaceAbi,
      this.wallet,
    ) as FuturesExchangeContract;
  }

  // UTIL → convert symbol to hex address
  private resolveToken(symbolOrAddress: string): string {
    const clean = String(symbolOrAddress).trim();

    if (clean.startsWith('0x')) return clean;

    const tokenAddr = this.tokenAddresses[clean.toUpperCase()];
    if (!tokenAddr) throw new Error(`Token symbol not registered: ${clean}`);

    if (!ethers.isAddress(tokenAddr)) {
      const tokenText = typeof tokenAddr === 'string' ? tokenAddr : '[invalid]';
      throw new Error(`Mapped token address is invalid: ${tokenText}`);
    }

    return tokenAddr;
  }

  private ensureUser(user: string): string {
    const clean = String(user ?? '').trim();

    if (!ethers.isAddress(clean)) {
      const safe = typeof clean === 'string' ? clean : '[invalid]';
      throw new Error(`Invalid user: ${safe}`);
    }
    return clean;
  }

  // ================= VAULT (READ-ONLY DARI BE) =================

  async getBalance(token: string, user: string): Promise<string> {
    const tokenAddr = this.resolveToken(token);
    const cleanUser = this.ensureUser(user);

    try {
      const bal = await this.vault.balanceOf(cleanUser, tokenAddr);
      return bal.toString();
    } catch (err) {
      this.logger.error(
        `getBalance error token=${tokenAddr} user=${cleanUser}: ${String(err)}`,
      );
      return '0';
    }
  }

  async getFreeBalance(token: string, user: string): Promise<string> {
    const tokenAddr = this.resolveToken(token);
    const cleanUser = this.ensureUser(user);

    try {
      const bal = await this.vault.freeBalanceOf(cleanUser, tokenAddr);
      return bal.toString();
    } catch (err) {
      this.logger.error(
        `freeBalance error token=${tokenAddr} user=${cleanUser}: ${String(err)}`,
      );
      return '0';
    }
  }

  // ================= EXCHANGE =================

  async openPosition(
    asset: string,
    size: string,
    isLong: boolean,
    collateralToken: string,
    collateralAmount: string,
  ): Promise<string> {
    const collateralAddr = this.resolveToken(collateralToken);
    return await this.exchange.openPosition(
      asset,
      size,
      isLong,
      collateralAddr,
      collateralAmount,
    );
  }

  async closePosition(
    positionId: string,
    collateralToken: string,
    collateralAmount: string,
  ): Promise<TransactionResponse> {
    const collateralAddr = this.resolveToken(collateralToken);
    const tx = await this.exchange.closePosition(
      positionId,
      collateralAddr,
      collateralAmount,
    );
    await tx.wait();
    return tx;
  }

  async getPosition(positionId: string): Promise<unknown> {
    return await this.exchange.getPosition(positionId);
  }
}
