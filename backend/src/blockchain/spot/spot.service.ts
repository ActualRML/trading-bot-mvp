import { Injectable, Logger } from '@nestjs/common';
import {
  Wallet,
  Contract,
  JsonRpcProvider,
  TransactionResponse,
  Interface,
  ethers,
  Log,
  NonceManager,
} from 'ethers';

import SpotVaultJson from './abis/SpotVault.json';
import SpotOrderBookJson from './abis/SpotOrderBook.json';
import SpotExchangeJson from './abis/SpotExchange.json';

// ====================
// Types
// ====================
export interface SpotVaultItem {
  asset: string;
  balance: string;
  locked: string;
}

type SpotVaultContract = Contract & {
  balances(token: string, user: string): Promise<bigint>;
  deposit(token: string, amount: string): Promise<TransactionResponse>;
  withdraw(token: string, amount: string): Promise<TransactionResponse>;
  transferBalance(
    token: string,
    from: string,
    to: string,
    amount: string,
  ): Promise<TransactionResponse>;

  depositFor(
    user: string,
    token: string,
    amount: string,
  ): Promise<TransactionResponse>;
  withdrawFor(
    user: string,
    token: string,
    amount: string,
  ): Promise<TransactionResponse>;
};

type SpotOrderBookContract = Contract & {
  createOrder(
    base: string,
    quote: string,
    price: string,
    amount: string,
    isBuy: boolean,
  ): Promise<TransactionResponse>;
  cancelOrder(orderId: number): Promise<TransactionResponse>;
  getOrder(orderId: number): Promise<unknown>;
  getUserOrders(user: string): Promise<unknown>;
};

type SpotExchangeContract = Contract & {
  executeMatch(
    buyOrderId: number,
    sellOrderId: number,
    matchAmount: string,
    matchPrice: string,
  ): Promise<TransactionResponse>;
};

@Injectable()
export class SpotService {
  private readonly logger = new Logger(SpotService.name);
  private readonly provider: JsonRpcProvider;
  private readonly wallet: NonceManager;
  private readonly backendAddress: string;

  private readonly DEFAULT_SPOT_ASSETS = ['BTC', 'ETH', 'USDT', 'SOL', 'ADA'];

  readonly vault: SpotVaultContract;
  readonly orderBook: SpotOrderBookContract;
  readonly exchange: SpotExchangeContract;

  private readonly orderBookInterface: Interface;

  // mapping symbol -> token address
  private readonly tokenAddresses: Record<string, string> = {
    BTC: String(process.env.TOKEN_BTC ?? '').trim(),
    ETH: String(process.env.TOKEN_ETH ?? '').trim(),
    USDT: String(process.env.TOKEN_USDT ?? '').trim(),
    SOL: String(process.env.TOKEN_SOL ?? '').trim(),
    ADA: String(process.env.TOKEN_ADA ?? '').trim(),
  };

  constructor() {
    const rpcUrl = String(process.env.RPC_URL ?? '').trim();
    if (!rpcUrl) throw new Error('RPC_URL not set in env');

    this.provider = new JsonRpcProvider(rpcUrl, {
      name: 'hardhat',
      chainId: 31337,
    });

    const privateKey = String(process.env.PRIVATE_KEY ?? '').trim();
    if (!privateKey || !privateKey.startsWith('0x')) {
      throw new Error('PRIVATE_KEY invalid or not set');
    }

    const baseWallet = new Wallet(privateKey, this.provider);
    this.wallet = new NonceManager(baseWallet);
    this.backendAddress = baseWallet.address;

    this.logger.log(
      '[SpotService] BACKEND WALLET = '.concat(baseWallet.address),
    );

    const vaultAddress = String(process.env.SPOT_VAULT ?? '').trim();
    const orderBookAddress = String(process.env.SPOT_ORDER_BOOK ?? '').trim();
    const exchangeAddress = String(process.env.SPOT_EXCHANGE ?? '').trim();

    if (
      !ethers.isAddress(vaultAddress) ||
      !ethers.isAddress(orderBookAddress) ||
      !ethers.isAddress(exchangeAddress)
    ) {
      throw new Error('Contract addresses invalid');
    }

    this.vault = new Contract(
      vaultAddress,
      SpotVaultJson,
      this.wallet,
    ) as SpotVaultContract;

    this.orderBook = new Contract(
      orderBookAddress,
      SpotOrderBookJson,
      this.wallet,
    ) as SpotOrderBookContract;

    this.exchange = new Contract(
      exchangeAddress,
      SpotExchangeJson,
      this.wallet,
    ) as SpotExchangeContract;

    this.orderBookInterface = new Interface(SpotOrderBookJson);
  }

  // helper untuk format error jadi string aman
  private formatError(error: unknown): string {
    if (error instanceof Error) return error.message;
    if (typeof error === 'string') return error;
    return 'Unknown error';
  }

  // =================
  // VAULT (READ ONLY DARI BE)
  // =================
  async getSpotVault(user: string): Promise<SpotVaultItem[]> {
    const cleanUser = String(user ?? '').trim();
    if (!ethers.isAddress(cleanUser)) return this.defaultZeros();

    const results: SpotVaultItem[] = [];

    for (const asset of this.DEFAULT_SPOT_ASSETS) {
      try {
        const balance = await this.getBalance(asset, cleanUser);
        results.push({ asset, balance: balance ?? '0', locked: '0' });
      } catch {
        results.push({ asset, balance: '0', locked: '0' });
      }
    }

    return results;
  }

  private defaultZeros(): SpotVaultItem[] {
    return this.DEFAULT_SPOT_ASSETS.map((asset) => ({
      asset,
      balance: '0',
      locked: '0',
    }));
  }

  async getBalance(symbol: string, user: string): Promise<string> {
    const token = this.tokenAddresses[symbol.toUpperCase()];

    this.logger.log('[DEBUG] getBalance', {
      symbol,
      token,
      user,
    });

    if (!ethers.isAddress(token) || !ethers.isAddress(user)) {
      this.logger.log('[DEBUG] getBalance invalid address', {
        symbol,
        token,
        user,
      });
      return '0';
    }

    try {
      const bal = await this.vault.balances(token, user);
      this.logger.log('[DEBUG] onchainBalance', {
        symbol,
        token,
        user,
        bal: bal.toString(),
      });
      return bal.toString();
    } catch (e) {
      this.logger.error('[DEBUG] getBalance error', {
        symbol,
        token,
        user,
        err: this.formatError(e),
      });
      return '0';
    }
  }

  // =================
  // ORDERBOOK
  // =================
  async createOrder(
    base: string,
    quote: string,
    price: string,
    amount: string,
    isBuy: boolean,
  ): Promise<number> {
    const baseAddr = base.trim();
    const quoteAddr = quote.trim();

    if (!ethers.isAddress(baseAddr) || !ethers.isAddress(quoteAddr)) {
      throw new Error('base/quote must be 0x... address');
    }

    try {
      const tx = await this.orderBook.createOrder(
        baseAddr,
        quoteAddr,
        price,
        amount,
        isBuy,
      );

      const receipt = await tx.wait();
      if (!receipt) throw new Error('Transaction receipt NULL');

      type ParsedLogShape = {
        name: string;
        args: Record<string, unknown> | unknown[];
      };

      let parsedLog: ParsedLogShape | null = null;

      for (const l of receipt.logs as Log[]) {
        try {
          const p = this.orderBookInterface.parseLog(l) as ParsedLogShape;
          if (!p || !p.name) continue;
          parsedLog = p;
          break;
        } catch {
          // ignore non-matching logs
        }
      }

      if (!parsedLog) throw new Error('OrderCreated log not found');

      const args = parsedLog.args;
      let maybeId: unknown = undefined;

      if (Array.isArray(args) && args.length > 0) {
        maybeId = args[0];
      } else if (args && typeof args === 'object') {
        if (Object.prototype.hasOwnProperty.call(args, 'orderId')) {
          maybeId = (args as Record<string, unknown>).orderId;
        } else {
          const numericKey = Object.keys(args).find((k) => /^\d+$/.test(k));
          if (numericKey) {
            maybeId = (args as Record<string, unknown>)[numericKey];
          }
        }
      }

      if (maybeId === undefined) {
        throw new Error('orderId not found in event args');
      }

      let idNum: number;
      if (typeof maybeId === 'bigint') {
        idNum = Number(maybeId);
      } else if (typeof maybeId === 'number') {
        idNum = maybeId;
      } else if (typeof maybeId === 'string') {
        const parsed = Number(maybeId);
        if (Number.isNaN(parsed)) {
          throw new Error('Invalid orderId (string not numeric)');
        }
        idNum = parsed;
      } else {
        throw new Error('Invalid orderId type');
      }

      if (Number.isNaN(idNum)) {
        throw new Error('Invalid orderId');
      }

      return idNum;
    } catch (error: unknown) {
      const msg = this.formatError(error);
      this.logger.error('createOrder failed', {
        base: baseAddr,
        quote: quoteAddr,
        err: msg,
      });
      throw error;
    }
  }

  async cancelOrder(orderId: number): Promise<string> {
    try {
      const tx = await this.orderBook.cancelOrder(orderId);
      await tx.wait();
      return tx.hash;
    } catch (error: unknown) {
      const msg = this.formatError(error);
      this.logger.error('cancelOrder failed', { orderId, err: msg });
      throw error;
    }
  }

  async getOrder(orderId: number): Promise<unknown> {
    try {
      return await this.orderBook.getOrder(orderId);
    } catch (error: unknown) {
      const msg = this.formatError(error);
      this.logger.error('getOrder failed', { orderId, err: msg });
      throw error;
    }
  }

  async getUserOrders(user: string): Promise<unknown> {
    const cleanUser = user.trim();
    if (!ethers.isAddress(cleanUser)) {
      throw new Error('Invalid user address');
    }

    try {
      return await this.orderBook.getUserOrders(cleanUser);
    } catch (error: unknown) {
      const msg = this.formatError(error);
      this.logger.error('getUserOrders failed', { user: cleanUser, err: msg });
      throw error;
    }
  }

  // =================
  // EXCHANGE
  // =================
  async executeMatch(
    buyOrderId: number,
    sellOrderId: number,
    matchAmount: string,
    matchPrice: string,
  ): Promise<string> {
    try {
      const tx = await this.exchange.executeMatch(
        buyOrderId,
        sellOrderId,
        matchAmount,
        matchPrice,
      );
      await tx.wait();
      return tx.hash;
    } catch (error: unknown) {
      const msg = this.formatError(error);
      this.logger.error('executeMatch failed', {
        buyOrderId,
        sellOrderId,
        err: msg,
      });
      throw error;
    }
  }
}
