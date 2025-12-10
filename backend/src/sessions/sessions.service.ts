import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Session, MarketType } from './sessions.entity';
import { UsersService } from '../users/users.service';
import { CreateSessionDTO } from './dto/create-sessions.dto';
import { SessionDTO } from './dto/sessions.dto';

@Injectable()
export class SessionsService {
  constructor(
    @InjectRepository(Session)
    private readonly sessionRepository: Repository<Session>,
    private readonly usersService: UsersService, // pakai service
  ) {}

  async createSession(body: CreateSessionDTO): Promise<SessionDTO> {
    const userEntity = await this.usersService.findOne(body.user_id);
    if (!userEntity) throw new BadRequestException('User not found');

    const session = this.sessionRepository.create({
      user: userEntity,
      strategy: body.strategy,
      market_type:
        body.market_type === 'spot' ? MarketType.SPOT : MarketType.FUTURES,
      result_summary: body.result_summary,
    });

    const saved = await this.sessionRepository.save(session);
    return this.toDTO(saved);
  }

  async getUserSessions(userId: number): Promise<SessionDTO[]> {
    const sessions = await this.sessionRepository.find({
      where: { user: { id: userId } },
      relations: ['user'],
      order: { created_at: 'DESC' },
    });
    return sessions.map((s) => this.toDTO(s));
  }

  private toDTO(session: Session): SessionDTO {
    return {
      id: session.id,
      user_id: session.user.id,
      strategy: session.strategy,
      market_type: session.market_type,
      result_summary: session.result_summary,
      created_at: session.created_at,
    };
  }
}
