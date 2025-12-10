import {
  Controller,
  Post,
  Body,
  InternalServerErrorException,
} from '@nestjs/common';
import { AuthService } from './auth.service';
import { User } from '../users/users.entity';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('nonce')
  async getNonce(
    @Body('eth_address') eth_address: string,
  ): Promise<{ nonce: number }> {
    const user: User = await this.authService.createOrUpdateNonce(eth_address);

    // Null check biar tipe narrow ke number
    if (user.nonce == null) {
      throw new InternalServerErrorException('Nonce not generated');
    }

    return { nonce: user.nonce };
  }

  @Post('verify')
  async verify(
    @Body() body: { eth_address: string; signature: string },
  ): Promise<{ success: boolean; token: string }> {
    const { token } = await this.authService.verifyNonce(
      body.eth_address,
      body.signature,
    );
    return { success: true, token };
  }
}
