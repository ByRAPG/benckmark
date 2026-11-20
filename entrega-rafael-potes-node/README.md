# Benchmark API de órdenes: NestJS + PostgreSQL

Autor: Rafael Potes. Taller de benchmarking de APIs con Postgres usando JMeter. El análisis completo está en [INFORME.md](INFORME.md).

## Estructura

```
.
├── docker-compose.yml     API + Postgres
├── init.sql               tablas orders y order_items
├── api/                   código NestJS y Dockerfile
├── jmeter/Benchmark.jmx   plan de pruebas
├── scripts/               level.ps1, probe.ps1, resources.py, jtl_stats.py, win.ps1
├── evidencias/
│   ├── capturas/          pantallazos por nivel y docker ps
│   ├── resultados/        Summary/Aggregate (csv), métricas (json), resources_report.csv
│   ├── busqueda_estres/   barrido para encontrar el estrés
│   └── raw/               JTL crudos y muestras de docker stats
├── INFORME.md
└── README.md
```

## Requisitos

- Docker Desktop (Compose v2)
- JMeter 5.6.3 con Java (las corridas se hicieron con Temurin 25)
- PowerShell y Python 3 para los scripts (solo si se quieren reproducir las corridas)

## Levantar el servicio

```bash
docker compose up -d --build
```

API en `http://localhost:5001`, Postgres en `localhost:5434` (usuario/clave `postgres`, base `orders_db`).

## Probar con curl

PowerShell:

```powershell
$body = '{"customerId":"C123","items":[{"productId":"P1","quantity":2,"price":10.5},{"productId":"P2","quantity":1,"price":5.0}]}'
Invoke-RestMethod -Method Post -Uri http://localhost:5001/api/orders -ContentType 'application/json' -Body $body
```

Bash:

```bash
curl -s -X POST http://localhost:5001/api/orders \
  -H "Content-Type: application/json" \
  -d '{"customerId":"C123","items":[{"productId":"P1","quantity":2,"price":10.5},{"productId":"P2","quantity":1,"price":5.0}]}'
```

Responde 201 con `orderId`, `totalAmount` (26), `itemsCount` (3) y `processedAt`.

## Abrir el plan en JMeter

```bash
jmeter -t jmeter/Benchmark.jmx -Jusers=50
```

Propiedades: `users`, `duration`, `rampup`, `port`, `jtl`.

## Reproducir las corridas

Corrida oficial con GUI y capturas (el script usa la ruta de JMeter `C:\apache-jmeter-5.6.3`):

```powershell
powershell -ExecutionPolicy Bypass -File scripts/level.ps1 -Users 50
```

Sondas headless para buscar el estrés:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/probe.ps1 -Levels 1400,1500
```

Reporte de consumo a partir de las muestras de `docker stats`:

```bash
python scripts/resources.py evidencias/raw evidencias/resultados/resources_report.csv
```

`evidencias/raw` contiene los JTL crudos de cada corrida oficial y los CSV de `docker stats`. Los JTL de las sondas de la búsqueda de estrés no se versionan por tamaño; su resumen está en `evidencias/busqueda_estres/busqueda_estres.csv`.