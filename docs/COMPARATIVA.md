# Comparativa grupal y conclusiones

**Taller:** Benchmarking de APIs con Postgres usando JMeter
**Repositorio:** https://github.com/lzayrox/benckmark
**Fecha:** 20 de noviembre de 2026

Todas las cifras salen de los CSV de cada carpeta (`*_aggregate.csv`, `resources_report.csv`). Las corridas oficiales son de 60 s. Cada integrante midió en su propio computador, como pide el enunciado.

## 1. Stacks y responsables

| Stack | Responsable | Entorno | Ubicación en el repo | Estado de la evidencia |
|---|---|---|---|---|
| Node.js 22 + NestJS 10 | Rafael Potes | Windows 11, Ryzen 5 8640HS (12 hilos), 36 GB, Docker Desktop con WSL2 | `entrega-rafael-potes-node/` | Completa: informe, 25 capturas, CSV, JTL |
| Java 21 + Spring Boot 3.4 | Orlando Palma | macOS 13, Apple M1, 8 GB, Docker sobre colima (VM de 4 CPU) | `entrega-orlando-palma-java/` | Completa: informe, capturas, CSV, JTL |
| Go (net/http + pgx) | Humberto Llinás | No documentado | `docs/go/` | Solo CSV y una captura por nivel; sin informe |
| Python (Flask + gunicorn) | Humberto Llinás | No documentado | `docs/python/` | Solo CSV y una captura por nivel; sin informe ni consumo |

Rust está implementado en `rust/`, pero no tiene resultados medidos y queda fuera de la comparación.

## 2. Tabla comparativa única

Cada celda: Avg (ms) / P95 (ms) / Throughput (req/s) / % Error.

| Stack | Baja (10) | Media (50) | Alta (100) | Estrés |
|---|---|---|---|---|
| Node.js (NestJS) | 14 / 27 / 634.43 / 0.00 % | 62 / 84 / 731.03 / 0.00 % | 125 / 163 / 727.54 / 0.00 % | **1500 usuarios:** 2025 / 2783 / 663.01 / **0.80 %** |
| Java (Spring Boot) | 2 / 3 / 4491.69 / 0.00 % | 8 / 16 / 5226.93 / 0.00 % | 19 / 48 / 4683.21 / 0.00 % | **1120 usuarios:** 337 / 563 / 2956.36 / **0.19 %** |
| Go (net/http + pgx) | 0 / 1 / 9687.30 / 0.00 % | 1 / 2 / 28433.10 / 0.00 % | 2 / 4 / 4426.88 / 0.00 % (**no válido**, ver nota 1). Referencia a 120 usuarios: 3 / 5 / 28902.06 / 0.00 % | Sin punto de fallo. Máximo válido, 250 usuarios: 10 / 15 / 23580.24 / 0.00 % |
| Python (Flask + gunicorn) | 1 / 3 / 4864.85 / 0.00 % | 7 / 11 / 6251.37 / 0.00 % | 15 / 20 / 6232.49 / 0.00 % | Sin punto de fallo. Máximo probado, 500 usuarios: 85 / 105 / 5579.21 / 0.00 % |

**Notas**

1. **Go, corridas no válidas.** Dividiendo muestras entre throughput, la corrida de 100 usuarios duró 776 s, la de 200 usuarios 4653 s y la de 500 usuarios 163 s, en vez de 60 s. Los listeners de JMeter acumularon muestras de corridas anteriores. Por eso el throughput de esas filas (4426.88, 746.73 y 18969.14 req/s) no es confiable y no se usa para conclusiones. Los niveles de 10, 50, 120, 140, 160 y 250 usuarios sí duraron 60 s. Hace falta repetir 100, 200 y 500 usuarios con datos limpios para tener el dato oficial.
2. **Estrés.** Solo Node y Java llegaron a un punto con errores. Go y Python no fallaron en los niveles probados (Go hasta 250 válidos, Python hasta 500), así que su "máxima carga" no es un punto de fallo.
3. **Los equipos son distintos.** Las diferencias reflejan lenguaje, pero también CPU, sistema operativo y Docker. Java corrió sobre una VM de colima en una máquina de 8 GB, y el cliente de carga compartía esa máquina.
4. En las corridas de Node y Java se verificó que el número de pedidos guardados en la base coincide con las peticiones exitosas.

## 3. Consumo del sistema

Valores promedio de `docker stats` (CPU en % de un núcleo; puede superar 100 %).

| Stack | Escenario | CPU API (%) | RAM API (MiB) | CPU DB (%) | RAM DB (MiB) | Observaciones |
|---|---|---|---|---|---|---|
| Node.js | Baja (10) | 96.4 | 66.4 | 59.6 | 94.8 | API ya cerca de un núcleo completo |
| Node.js | Media (50) | 102.0 | 104.8 | 72.5 | 135.2 | Event loop saturado; sin errores |
| Node.js | Alta (100) | 105.5 | 99.3 | 72.2 | 139.7 | Mismo techo de throughput |
| Node.js | Estrés (1500) | 106.5 | 160.2 | 67.4 | 142.9 | Cola larga; timeouts de cliente |
| Java | Baja (10) | 95.1 | 320.0 | 90.1 | 216.1 | Memoria alta desde el inicio (JVM) |
| Java | Media (50) | 112.7 | 320.3 | 111.3 | 221.3 | Sin errores |
| Java | Alta (100) | 123.5 | 365.8 | 115.1 | 229.2 | Sin errores |
| Java | Estrés (1120) | 118.6 | 524.4 | 107.1 | 232.9 | Errores de conexión del reenvío de puertos |
| Go | Baja (10) | 102.8 | 21.6 | 83.4 | 214.9 | Memoria mínima |
| Go | Media (50) | 235.8 | 28.2 | 217.9 | 277.5 | Usa varios núcleos |
| Go | 250 usuarios | 155.0 | 28.9 | 138.2 | 280.8 | Dato único del reporte |
| Python | todos | no registrado | no registrado | no registrado | no registrado | No existe `resources_report.csv` |

Go y Python no tienen medición de consumo en el nivel de 100 usuarios con datos válidos; el reporte de Go de ese nivel proviene de la corrida contaminada.

## 4. Conclusiones

### Rendimiento

1. **Mejor latencia promedio.** Go en todos los niveles con datos válidos: 0 ms (10 usuarios) y 1 ms (50), frente a 1 y 7 ms de Python, 2 y 8 ms de Java y 14 y 62 ms de Node. A 100 usuarios Python promedia 15 ms, Java 19 ms y Node 125 ms; el dato de Go a 100 usuarios no es válido y su referencia más cercana (120 usuarios) es de 3 ms. Con la salvedad de los equipos distintos, el orden es Go, Java y Python parecidos en niveles bajos, y Node claramente por detrás.
2. **Mejor throughput en cargas altas.** Go, con 28 433 a 29 007 req/s entre 50 y 160 usuarios en corridas de 60 s. Después Python (unos 6200 req/s estables de 50 a 250 usuarios), luego Java (4683 a 5227 req/s hasta 100 usuarios) y Node (unos 730 req/s). A 50 usuarios, Java rinde cerca de 7 veces lo de Node y Go cerca de 39 veces, pero en máquinas distintas.
3. **Lenguaje más estable.** Go y Python no tuvieron errores en ningún nivel probado. Python mantuvo un throughput casi plano (6127 a 6251 req/s de 50 a 250 usuarios, 5579 a 500). Go también, entre 50 y 160 usuarios. Java fue estable hasta 100 usuarios. Node mantuvo su throughput, pero su latencia creció casi en proporción a los usuarios.

### Eficiencia

4. **Errores bajo alta carga.** Sí, en dos stacks: Node a 1500 usuarios (0.80 %, 336 de 41 781 peticiones) y Java a 1120 usuarios (0.19 %, 354 de 184 477). Go y Python no presentaron errores en los niveles medidos.
5. **Qué explica las fallas.**
   - *Node:* los 336 errores son `SocketTimeoutException: Read timed out` (el cliente espera 10 s). No hubo ningún error 5xx y todos los pedidos aceptados quedaron en la base. El proceso de Node usó cerca de un núcleo completo, y con un único event loop las peticiones se encolan hasta superar el timeout. La CPU de la base de datos estuvo entre 60 % y 73 %, así que el límite está en la API.
   - *Java:* los 354 errores son `Connection refused` en `localhost:5002`, sin errores 5xx. El informe de Orlando atribuye el techo al reenvío de puertos de colima en macOS y lo respalda con pruebas internas a la VM. Es una conclusión de su entorno; no está comprobado en Linux nativo.
   - Si el cuello de Node es el modelo de un solo hilo (como indican el uso de CPU y el patrón de timeouts), es una explicación razonada, no una medición directa de cada causa.

### Recomendación

6. **Alto desempeño.** Go: el mayor throughput, la menor latencia y la menor memoria (21 a 29 MiB de API) entre los stacks con datos válidos. Java con Spring Boot sería la alternativa si la empresa ya trabaja con ese ecosistema.
7. **Más fácil de implementar pero menos rendidor.** Node con NestJS fue el más lento de la comparación (unos 730 req/s). La facilidad de desarrollo es una apreciación cualitativa de la estructura de NestJS (decoradores, módulos, tipado), no una medición. Para escalarlo hay que usar varias instancias.
8. **Mejor balance entre sencillez y velocidad.** Python con Flask: su implementación es corta (`app.py` y `database.py` suman 82 líneas) y alcanzó unos 6200 req/s sin errores hasta 500 usuarios, mucho más que Node y más que Java en esta medición. Go da más velocidad, pero con una implementación algo más extensa.

## 5. Limitaciones

- **Hardware y sistema operativo distintos** por integrante: Windows con WSL2, macOS con colima y un entorno no documentado para Go y Python. No es una comparación de laboratorio.
- **Cliente y servidor en la misma máquina:** JMeter compite por CPU con la API y la base de datos. En Java además corre con 8 GB de RAM compartidos con la VM.
- **Go:** las corridas de 100, 200 y 500 usuarios no son válidas (ver nota 1 de la sección 2). Para el dato oficial hay que repetirlas con los listeners limpios.
- **Go y Python no tienen informe individual ni las 5 capturas por nivel** que pide el profesor, y se desconocen su equipo y su configuración de recursos.
- **Estrés distinto por stack:** cada uno se buscó hasta su primer error (Node 1500, Java 1120) o hasta el máximo probado (Go, Python), así que los niveles de usuarios no son iguales.
- **Rust** no se midió.
