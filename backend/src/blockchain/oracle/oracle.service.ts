import { Injectable } from '@nestjs/common';
import { Wallet, Contract, JsonRpcProvider, Interface } from 'ethers';
import PriceOracleRouterJson from './abis/PriceOracleRouter.json';

const priceOracleRouterAbi = new Interface(PriceOracleRouterJson);

@Injectable()
export class OracleService {
  private provider: JsonRpcProvider;
  private wallet: Wallet;
  public router: Contract;

  constructor() {
    const rpcUrl = process.env.RPC_URL?.trim();
    if (!rpcUrl) throw new Error('RPC_URL not set in env');
    this.provider = new JsonRpcProvider(rpcUrl);

    const privateKey = process.env.PRIVATE_KEY?.trim();
    if (!privateKey) throw new Error('PRIVATE_KEY not set in env');
    this.wallet = new Wallet(privateKey, this.provider);

    const routerAddress = process.env.PRICE_ORACLE_ROUTER?.trim();
    if (!routerAddress) throw new Error('PRICE_ORACLE_ROUTER not set in env');

    this.router = new Contract(
      routerAddress,
      priceOracleRouterAbi,
      this.wallet,
    );
  }

  async getPrice(priceId: string): Promise<string> {
    const price: unknown = await this.router.getPrice(priceId);
    return String(price);
  }
}
