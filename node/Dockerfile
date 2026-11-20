FROM oven/bun:1-alpine

WORKDIR /app

# Instala dependencias (en milisegundos con bun)
COPY package.json .
RUN bun install

# Copia tsconfig.json (para que Bun respete emitDecoratorMetadata) y el código
COPY tsconfig.json .
COPY src ./src

EXPOSE 8080

CMD ["bun", "run", "src/main.ts"]