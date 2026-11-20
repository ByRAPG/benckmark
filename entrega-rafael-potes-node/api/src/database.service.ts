import { Injectable, OnModuleDestroy } from '@nestjs/common';
import { Pool } from 'pg';

export interface OrderItemDto {
  productId: string;
  quantity: number;
  price: number;
}

@Injectable()
export class DatabaseService implements OnModuleDestroy {
  private readonly pool: Pool;

  constructor() {
    this.pool = new Pool({
      host: process.env.DB_HOST || 'db',
      port: Number(process.env.DB_PORT || 5432),
      user: process.env.DB_USER || 'postgres',
      password: process.env.DB_PASSWORD || 'postgres',
      database: process.env.DB_NAME || 'orders_db',
      max: Number(process.env.DB_POOL_MAX || 30),
    });
  }

  async onModuleDestroy() {
    await this.pool.end();
  }

  async insertOrder(
    orderId: string,
    customerId: string,
    totalAmount: number,
    itemsCount: number,
    items: OrderItemDto[],
  ): Promise<Date> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      const orderRes = await client.query<{ created_at: Date }>(
        `INSERT INTO orders (order_id, customer_id, total_amount, items_count)
         VALUES ($1, $2, $3, $4)
         RETURNING created_at`,
        [orderId, customerId, totalAmount, itemsCount],
      );

      // Un solo INSERT multi-VALUES parametrizado para order_items
      const values: any[] = [];
      const placeholders = items.map((item, idx) => {
        const offset = idx * 4;
        values.push(orderId, item.productId, item.quantity, item.price);
        return `($${offset + 1}, $${offset + 2}, $${offset + 3}, $${offset + 4})`;
      });

      await client.query(
        `INSERT INTO order_items (order_id, product_id, quantity, price)
         VALUES ${placeholders.join(', ')}`,
        values,
      );

      await client.query('COMMIT');
      return orderRes.rows[0].created_at;
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }
}
