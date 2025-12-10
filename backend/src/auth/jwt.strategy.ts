// src/auth/jwt.strategy.ts
import { Injectable } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { Strategy, StrategyOptions } from 'passport-jwt';
import { Request } from 'express';

export interface JwtPayload {
  sub: number;
  wallet: string;
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor() {
    // extractor Bearer token sendiri, tanpa ExtractJwt (biar gak kena any)
    const jwtFromRequest = (req: Request): string | null => {
      const authHeader = req.headers?.authorization;
      if (!authHeader || typeof authHeader !== 'string') return null;

      const [scheme, token] = authHeader.split(' ');
      if (scheme !== 'Bearer' || !token) return null;

      return token;
    };

    const options: StrategyOptions = {
      jwtFromRequest,
      ignoreExpiration: false,
      secretOrKey: process.env.JWT_SECRET ?? 'dev_secret_key',
    };

    // Nest + passport-jwt typings bikin ESLint pikir ini 'unsafe call'
    // Secara runtime ini aman, jadi kita matikan rule hanya di baris ini.
    // eslint-disable-next-line @typescript-eslint/no-unsafe-call
    super(options);
  }

  // tidak perlu async, tidak ada await
  validate(payload: JwtPayload) {
    // ini yang nanti ada di req.user
    return {
      id: payload.sub,
      wallet: payload.wallet,
    };
  }
}
