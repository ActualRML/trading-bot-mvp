import { OrderSide, OrderStatus } from '../orders.entity';

export interface OrderDTO {
  id: number;
  user_id: number;
  asset_id: number;
  side: OrderSide;
  status: OrderStatus;
  amount: string;
  price: string;
  createdAt: Date;
  updatedAt: Date;
}
