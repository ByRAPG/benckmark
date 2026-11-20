# Etapa 1: Compilación optimizada (--release)
FROM rust:alpine AS builder

WORKDIR /app

# Instala musl-dev para compilar crates en Alpine
RUN apk add --no-cache musl-dev

# Pre-compila dependencias para aprovechar la caché de Docker
COPY Cargo.toml .
RUN mkdir src && \
    echo "fn main() {}" > src/main.rs && \
    cargo build --release && \
    rm -rf src

# Copia el código real y compila el binario final
COPY src ./src
RUN touch src/main.rs && \
    cargo build --release --bin benchmark-rust

# Etapa 2: Imagen final mínima
FROM alpine:3.20

WORKDIR /app
COPY --from=builder /app/target/release/benchmark-rust ./server

EXPOSE 8080

CMD ["./server"]