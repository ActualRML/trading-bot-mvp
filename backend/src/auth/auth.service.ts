// src/auth/auth.service.ts
import { Injectable, UnauthorizedException } from '@nestjs/common';
import { UsersService } from '../users/users.service';
import { User } from '../users/users.entity';
import { verifyMessage } from 'ethers';
import { JwtService } from '@nestjs/jwt';

@Injectable()
export class AuthService {
  constructor(
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
  ) {}

  /**
   * Generate or update nonce when user requests login.
   * Jika wallet belum terdaftar -> AUTO REGISTER user baru.
   */
  async createOrUpdateNonce(eth_address: string): Promise<User> {
    const normalized = eth_address.toLowerCase();

    const user = await this.usersService.findByAddress(normalized);

    // AUTO-REGISTER JIKA BELUM ADA
    if (!user) {
      const newUser = await this.usersService.create({
        eth_address: normalized,
        nonce: Math.floor(Math.random() * 1000000),
        role: 'user',
        status: 'active',
      });

      return newUser;
    }

    // USER SUDAH ADA -> UPDATE NONCE
    const newNonce = Math.floor(Math.random() * 1000000);

    const updatedUser = await this.usersService.update(user.id, {
      nonce: newNonce,
    });

    if (!updatedUser) {
      throw new UnauthorizedException('Wallet not found');
    }

    return updatedUser;
  }

  /**
   * Verify nonce + signature, lalu generate JWT token.
   */
  async verifyNonce(
    eth_address: string,
    signature: string,
  ): Promise<{ user: User; token: string }> {
    const normalized = eth_address.toLowerCase();
    const user = await this.usersService.findByAddress(normalized);

    if (!user) {
      throw new UnauthorizedException('Wallet not registered');
    }

    if (!user.eth_address) {
      throw new UnauthorizedException('User wallet address is missing');
    }

    // Message yang disign user (harus sama persis dengan FE)
    const msg = `Login nonce: ${user.nonce}`;

    // Recover address dari signature
    const recoveredAddress = verifyMessage(msg, signature);

    if (recoveredAddress.toLowerCase() !== user.eth_address.toLowerCase()) {
      throw new UnauthorizedException('Invalid signature');
    }

    // ROTATE NONCE SETELAH BERHASIL LOGIN
    const newNonce = Math.floor(Math.random() * 1000000);

    const updatedUser = await this.usersService.update(user.id, {
      nonce: newNonce,
    });

    if (!updatedUser) {
      throw new UnauthorizedException('Wallet not found');
    }

    // GENERATE JWT
    const token = this.jwtService.sign({
      sub: user.id,
      wallet: user.eth_address,
    });

    return { user: updatedUser, token };
  }
}
