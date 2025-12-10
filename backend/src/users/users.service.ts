// src/users/users.service.ts
import { Injectable } from '@nestjs/common';
import { Repository } from 'typeorm';
import { InjectRepository } from '@nestjs/typeorm';
import { User } from './users.entity';
import { CreateUserDto } from './dto/create-user.dto';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private usersRepository: Repository<User>,
  ) {}

  // ===== CRUD STANDARD =====
  findAll(): Promise<User[]> {
    return this.usersRepository.find();
  }

  findOne(id: number): Promise<User | null> {
    return this.usersRepository.findOneBy({ id });
  }

  create(dto: CreateUserDto): Promise<User> {
    // Normalisasi eth_address ke lowercase kalau ada
    const payload: CreateUserDto = {
      ...dto,
      eth_address: dto.eth_address
        ? dto.eth_address.toLowerCase()
        : dto.eth_address,
    };

    const user = this.usersRepository.create(payload);
    return this.usersRepository.save(user);
  }

  async update(id: number, dto: Partial<User>): Promise<User | null> {
    const user = await this.usersRepository.findOneBy({ id });
    if (!user) return null;

    const patch: Partial<User> = {
      ...dto,
      eth_address: dto.eth_address
        ? dto.eth_address.toLowerCase()
        : (dto.eth_address ?? user.eth_address),
    };

    Object.assign(user, patch);
    return this.usersRepository.save(user);
  }

  async remove(id: number): Promise<User | null> {
    const user = await this.usersRepository.findOneBy({ id });
    if (!user) return null;

    await this.usersRepository.remove(user);
    return user;
  }

  // ===== HELPER UNTUK AUTH/WALLETS =====
  async findByAddress(eth_address: string): Promise<User | null> {
    const normalized = eth_address.toLowerCase();
    return this.usersRepository.findOne({
      where: { eth_address: normalized },
    });
  }

  // Alias supaya controller bisa pakai nama yang lebih konsisten
  async findByEthAddress(eth_address: string): Promise<User | null> {
    return this.findByAddress(eth_address);
  }
}
