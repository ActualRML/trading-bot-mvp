import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  BadRequestException,
  NotFoundException,
  Put,
} from '@nestjs/common';
import { OrdersService } from './orders.service';
import { UsersService } from '../users/users.service';
import { AssetsService } from '../assets/assets.service';
import { OrderStatus, OrderSide } from './orders.entity';
import { OrderDTO } from './dto/orders.dto';

@Controller('orders')
export class OrdersController {
  constructor(
    private readonly ordersService: OrdersService,
    private readonly usersService: UsersService,
    private readonly assetsService: AssetsService,
  ) {}

  @Get('user/:userId')
  async getUserOrders(@Param('userId') userId: number): Promise<OrderDTO[]> {
    return this.ordersService.getUserOrders(userId);
  }

  @Post('create')
  async createOrder(
    @Body()
    body: {
      userId: number;
      assetId: number;
      side: 'BUY' | 'SELL';
      amount: string;
      price: string;
    },
  ): Promise<OrderDTO> {
    const user = await this.usersService.findOne(body.userId);
    if (!user) throw new BadRequestException('User not found');

    const asset = await this.assetsService.findOne(body.assetId);
    if (!asset) throw new NotFoundException('Asset not found');

    const side: OrderSide =
      body.side === 'BUY' ? OrderSide.BUY : OrderSide.SELL;

    return this.ordersService.createOrder({
      user,
      asset,
      side,
      amount: body.amount,
      price: body.price,
    });
  }

  @Put('update-status')
  async updateOrderStatus(
    @Body() body: { orderId: number; status: OrderStatus },
  ): Promise<OrderDTO> {
    return this.ordersService.updateOrderStatus(body.orderId, body.status);
  }
}
