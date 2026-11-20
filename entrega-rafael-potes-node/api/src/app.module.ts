import { Module } from '@nestjs/common';
import { DatabaseService } from './database.service';
import { OrdersController } from './orders.controller';

@Module({
  controllers: [OrdersController],
  providers: [DatabaseService],
})
export class AppModule {}
