import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  BadRequestException,
} from '@nestjs/common';
import { SessionsService } from './sessions.service';
import { UsersService } from '../users/users.service';
import { SessionDTO } from './dto/sessions.dto';

@Controller('sessions')
export class SessionsController {
  constructor(
    private readonly sessionsService: SessionsService,
    private readonly usersService: UsersService,
  ) {}

  @Get('user/:userId')
  async getUserSessions(
    @Param('userId') userId: number,
  ): Promise<SessionDTO[]> {
    return this.sessionsService.getUserSessions(userId);
  }

  @Post('create')
  async createSession(
    @Body()
    body: {
      user_id: number;
      strategy: string;
      market_type: 'spot' | 'futures';
      result_summary?: string;
    },
  ): Promise<SessionDTO> {
    const user = await this.usersService.findOne(body.user_id);
    if (!user) throw new BadRequestException('User not found');

    return this.sessionsService.createSession(body);
  }
}
