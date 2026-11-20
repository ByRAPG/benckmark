import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const port = Number(process.env.PORT || 5001);
  const app = await NestFactory.create(AppModule, { logger: ['error', 'warn'] });
  await app.listen(port, '0.0.0.0');
  console.log(`Servidor NestJS escuchando en :${port}`);
}
bootstrap();
