import { Injectable } from '@nestjs/common';
import {
  Wallet,
  Contract,
  JsonRpcProvider,
  Interface,
  keccak256,
  toUtf8Bytes,
  type BytesLike,
  type BigNumberish,
  type ContractTransactionResponse,
} from 'ethers';
import MockOracleJson from './abis/MockOracle.json';

const mockPriceOracleAbi = new Interface(MockOracleJson.abi);

@Injectable()
export class MockOracleService {
  private provider: JsonRpcProvider;
  private wallet: Wallet;
  public mockOracle: Contract;

  constructor() {
    const rpcUrl = process.env.RPC_URL?.trim();
    if (!rpcUrl) throw new Error('RPC_URL not set in env');
    this.provider = new JsonRpcProvider(rpcUrl);

    const privateKey = process.env.PRIVATE_KEY?.trim();
    if (!privateKey) throw new Error('PRIVATE_KEY not set in env');
    this.wallet = new Wallet(privateKey, this.provider);

    const mockOracleAddress = process.env.MOCK_ORACLE?.trim();
    if (!mockOracleAddress) throw new Error('MOCK_ORACLE not set in env');

    this.mockOracle = new Contract(
      mockOracleAddress,
      mockPriceOracleAbi,
      this.wallet,
    );
  }

  /**
   * Ambil harga asset dari mock oracle
   * @param priceId string key, bisa nama asset seperti "BTC" atau hash
   */
  async getPrice(priceId: string | Uint8Array | Buffer): Promise<string> {
    // kalau input string, ubah ke bytes32 hash
    const priceKey: BytesLike =
      typeof priceId === 'string' ? keccak256(toUtf8Bytes(priceId)) : priceId;

    const price = (await this.mockOracle.getPrice(priceKey)) as BigNumberish;
    return price.toString();
  }

  /**
   * Set harga asset (optional, buat development/test)
   */
  async setPrice(asset: string, price: BigNumberish): Promise<void> {
    const priceKey = keccak256(toUtf8Bytes(asset));

    const tx = (await this.mockOracle.setPrice(
      priceKey,
      price,
    )) as ContractTransactionResponse;

    await tx.wait();
  }
}
