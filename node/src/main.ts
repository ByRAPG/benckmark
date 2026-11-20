// node/src/main.ts
import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, { logger: ['error', 'warn'] });
  await app.listen(8080, '0.0.0.0');
  console.log('Servidor NestJS escuchando en :8080');
}
bootstrap();