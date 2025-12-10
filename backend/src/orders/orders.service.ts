import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Order, OrderSide, OrderStatus } from './orders.entity';
import { OrderDTO } from './dto/orders.dto';
import { User } from '../users/users.entity';
import { Asset } from '../assets/assets.entity';

@Injectable()
export class OrdersService {
  constructor(
    @InjectRepository(Order)
    private readonly orderRepository: Repository<Order>,
  ) {}

  // ambil semua order user
  async getUserOrders(userId: number): Promise<OrderDTO[]> {
    const orders = await this.orderRepository.find({
      where: { user: { id: userId } },
      relations: ['user', 'asset'], // wallet dihapus
    });
    return orders.map((order) => this.toDTO(order));
  }

  // buat order baru
  async createOrder(data: {
    user: User;
    asset: Asset;
    side: OrderSide;
    amount: string;
    price: string;
  }): Promise<OrderDTO> {
    const order = this.orderRepository.create({
      user: data.user,
      asset: data.asset,
      side: data.side,
      amount: data.amount,
      price: data.price,
      status: OrderStatus.PENDING,
    });

    const saved = await this.orderRepository.save(order);
    return this.toDTO(saved);
  }

  // update status order
  async updateOrderStatus(
    orderId: number,
    status: OrderStatus,
  ): Promise<OrderDTO> {
    const order = await this.orderRepository.findOne({
      where: { id: orderId },
      relations: ['user', 'asset'], // wallet dihapus
    });

    if (!order) throw new NotFoundException('Order not found');

    order.status = status;
    const saved = await this.orderRepository.save(order);
    return this.toDTO(saved);
  }

  // helper: convert Order entity ke DTO
  private toDTO(order: Order): OrderDTO {
    return {
      id: order.id,
      user_id: order.user.id,
      asset_id: order.asset.id,
      side: order.side,
      status: order.status,
      amount: order.amount,
      price: order.price,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
    };
  }
}
