# Etapa 1: Compilación dentro de Docker
FROM golang:alpine AS builder

WORKDIR /app

# Copia main.go y la carpeta database/
COPY . .

# Inicializa el módulo, descarga pgx y uuid, y compila
RUN go mod init benchmark-go && \
    go mod tidy && \
    CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o server .

# Etapa 2: Imagen final mínima
FROM alpine:3.20

WORKDIR /app
COPY --from=builder /app/server .

EXPOSE 8080

CMD ["./server"]