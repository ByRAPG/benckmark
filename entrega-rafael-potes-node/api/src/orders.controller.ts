import {
  BadRequestException,
  Body,
  Controller,
  HttpCode,
  HttpStatus,
  Post,
} from '@nestjs/common';
import { randomUUID } from 'crypto';
import { DatabaseService, OrderItemDto } from './database.service';

interface CreateOrderRequest {
  customerId: string;
  items: OrderItemDto[];
}

@Controller('api/orders')
export class OrdersController {
  constructor(private readonly databaseService: DatabaseService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async createOrder(@Body() body: CreateOrderRequest) {
    if (
      !body?.customerId ||
      typeof body.customerId !== 'string' ||
      !Array.isArray(body.items) ||
      body.items.length === 0
    ) {
      throw new BadRequestException('customerId e items son requeridos');
    }

    let totalAmount = 0;
    let itemsCount = 0;

    for (const item of body.items) {
      totalAmount += Number(item.quantity) * Number(item.price);
      itemsCount += Number(item.quantity);
    }
    totalAmount = Math.round(totalAmount * 100) / 100;

    const orderId = `ORD-${randomUUID()}`;
    const processedAt = await this.databaseService.insertOrder(
      orderId,
      body.customerId,
      totalAmount,
      itemsCount,
      body.items,
    );

    return {
      orderId,
      customerId: body.customerId,
      totalAmount,
      itemsCount,
      processedAt: processedAt.toISOString(),
    };
  }
}
