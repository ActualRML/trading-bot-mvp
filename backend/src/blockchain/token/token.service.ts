/* eslint-disable @typescript-eslint/no-unsafe-member-access */
/* eslint-disable @typescript-eslint/no-unsafe-assignment */
import { Injectable } from '@nestjs/common';
import { Wallet, Contract, JsonRpcProvider, formatEther } from 'ethers';
import tokenJson from './abis/MockToken.json';

// Ambil ABI
const tokenAbi: any[] = (tokenJson as any).abi;

@Injectable()
export class TokenService {
  private provider: JsonRpcProvider;
  private wallet: Wallet;

  public tokenBTC: Contract;
  public tokenETH: Contract;
  public tokenUSDT: Contract;
  public tokenSOL: Contract;
  public tokenADA: Contract;

  constructor() {
    // === Setup Provider ===
    const rpcUrl = process.env.RPC_URL?.trim();
    if (!rpcUrl) throw new Error('RPC_URL not set in env');
    this.provider = new JsonRpcProvider(rpcUrl);

    // === Setup Wallet ===
    const privateKey = process.env.PRIVATE_KEY?.trim();
    if (!privateKey) throw new Error('PRIVATE_KEY not set in env');
    if (!/^0x[a-fA-F0-9]{64}$/.test(privateKey)) {
      throw new Error(`PRIVATE_KEY invalid format: ${privateKey}`);
    }
    this.wallet = new Wallet(privateKey, this.provider);

    // === Setup Contracts ===
    const tokenBtcAddress = process.env.TOKEN_BTC?.trim();
    const tokenEthAddress = process.env.TOKEN_ETH?.trim();
    const tokenUsdtAddress = process.env.TOKEN_USDT?.trim();
    const tokenSolAddress = process.env.TOKEN_SOL?.trim();
    const tokenAdaAddress = process.env.TOKEN_ADA?.trim();

    if (!tokenBtcAddress) throw new Error('TOKEN_BTC not set in env');
    if (!tokenEthAddress) throw new Error('TOKEN_ETH not set in env');
    if (!tokenUsdtAddress) throw new Error('TOKEN_USDT not set in env');
    if (!tokenSolAddress) throw new Error('TOKEN_SOL not set in env');
    if (!tokenAdaAddress) throw new Error('TOKEN_ADA not set in env');

    this.tokenBTC = new Contract(tokenBtcAddress, tokenAbi, this.wallet);
    this.tokenETH = new Contract(tokenEthAddress, tokenAbi, this.wallet);
    this.tokenUSDT = new Contract(tokenUsdtAddress, tokenAbi, this.wallet);
    this.tokenSOL = new Contract(tokenSolAddress, tokenAbi, this.wallet);
    this.tokenADA = new Contract(tokenAdaAddress, tokenAbi, this.wallet);
  }

  getWalletAddress(): string {
    return this.wallet.address;
  }

  async getBTCBalance(): Promise<string> {
    const balance = (await this.tokenBTC.balanceOf(
      this.wallet.address,
    )) as bigint;
    return formatEther(balance);
  }

  async getETHBalance(): Promise<string> {
    const balance = (await this.tokenETH.balanceOf(
      this.wallet.address,
    )) as bigint;
    return formatEther(balance);
  }

  async getUSDTBalance(): Promise<string> {
    const balance = (await this.tokenUSDT.balanceOf(
      this.wallet.address,
    )) as bigint;
    return formatEther(balance);
  }

  async getSOLBalance(): Promise<string> {
    const balance = (await this.tokenSOL.balanceOf(
      this.wallet.address,
    )) as bigint;
    return formatEther(balance);
  }

  async getADABalance(): Promise<string> {
    const balance = (await this.tokenADA.balanceOf(
      this.wallet.address,
    )) as bigint;
    return formatEther(balance);
  }
}
