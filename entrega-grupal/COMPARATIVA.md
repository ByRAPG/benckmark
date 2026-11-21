# Comparativa Grupal y Conclusiones del Taller de Benchmarking

**Taller:** Benchmarking de APIs con PostgreSQL usando Apache JMeter  
**Repositorio grupal:** `https://github.com/lzayrox/benckmark`  
**Fecha:** 20 de noviembre de 2026  

---

## 1. Integrantes del Grupo y Distribución de Stacks

En cumplimiento del enunciado oficial del taller ("Trabajo en grupo de estudiantes, pero cada integrante trabaja en su propio computador, con su propio proyecto y su propio docker-compose"), la distribución de responsabilidades y stacks fue la siguiente:

| Integrante | Stack Evaluado | Entorno de Ejecución | Carpeta en Repositorio | Estado |
|---|---|---|---|---|
| **Rafael Potes** | **Node.js 22 + NestJS 10** + PostgreSQL 16 | Windows 11 Pro, AMD Ryzen 5 8640HS (12 hilos, 36 GB RAM), WSL2 + Docker Desktop 29.9.3 | `entrega-rafael-potes-node/` | Entregado (PR #1 fusionado en `main`) |
| **Orlando Palma** | **Java 21 + Spring Boot 3.4** + PostgreSQL 16 | macOS Ventura, Apple M1 (8 núcleos, 8 GB RAM), Docker sobre colima VM (4 vCPU, 3.8 GiB) | `entrega-orlando-palma-java/` | Entregado (PR #3 fusionado en `main`) |
| **Humberto Llinás** | **Go (net/http + pgx; versión no documentada)** + PostgreSQL 16 | No documentado (pendiente confirmar SO, CPU y RAM con Humberto) | `docs/go/` | Datos preliminares en docs/ (pendiente informe formal y capturas oficiales) |
| **Humberto Llinás** | **Python (Flask + Gunicorn; versión no documentada)** + PostgreSQL 16 | No documentado (pendiente confirmar SO, CPU y RAM con Humberto) | `docs/python/` | Datos preliminares en docs/ (pendiente informe formal, capturas y resources_report.csv) |

Cada microservicio implementó el endpoint obligatorio `POST /api/orders` con transacción ACID contra PostgreSQL 16, insertando cabecera en `orders` y detalle en `order_items`, calculando `totalAmount` e `itemsCount` y retornando HTTP 201 con `orderId`, totales y `processedAt`.

---

## 2. Tabla Comparativa Única Consolidada

La siguiente tabla consolida los resultados obtenidos por los 4 stacks bajo los tres escenarios estándar (Baja: 10 usuarios, Media: 50 usuarios, Alta: 100 usuarios) y el escenario de **Estrés / Máxima Carga Probada**.

Todas las corridas oficiales debían ejecutarse durante **60 segundos** con **10 segundos de rampa (ramp-up)** a través de Apache JMeter.

| Stack | Métrica | Baja carga (10 usuarios) | Media carga (50 usuarios) | Alta carga (100 usuarios) | Máxima carga probada / Estrés |
|---|---|---|---|---|---|
| **Node.js (NestJS)**<br>*(Rafael Potes)* | **Avg (ms)**<br>**P95 (ms)**<br>**Throughput (req/s)**<br>**% Error**<br>**Muestras / Duración** | 14 ms<br>27 ms<br>634.43 req/s<br>**0.00 %**<br>*(38,009 / 59.9 s)* | 62 ms<br>84 ms<br>731.03 req/s<br>**0.00 %**<br>*(43,867 / 60.0 s)* | 125 ms<br>163 ms<br>727.54 req/s<br>**0.00 %**<br>*(43,746 / 60.1 s)* | *(1500 usuarios - Estrés / Fallo)\*<br>2025 ms<br>2783 ms<br>663.01 req/s<br>**0.80 %** *(336 timeouts de cliente)<br>*(41,781 / 63.0 s)* |
| **Java (Spring Boot)**<br>*(Orlando Palma)* | **Avg (ms)**<br>**P95 (ms)**<br>**Throughput (req/s)**<br>**% Error**<br>**Muestras / Duración** | 2 ms<br>3 ms<br>4491.69 req/s<br>**0.00 %**<br>*(269,290 / 60.0 s)* | 8 ms<br>16 ms<br>5226.93 req/s<br>**0.00 %**<br>*(313,480 / 60.0 s)* | 19 ms<br>48 ms<br>4683.21 req/s<br>**0.00 %**<br>*(281,175 / 60.0 s)* | *(1120 usuarios - Estrés / Fallo)\*<br>337 ms<br>563 ms<br>2956.36 req/s<br>**0.19 %** *(354 connection refused colima)<br>*(184,477 / 62.4 s)* |
| **Go (net/http + pgx)**<br>*(Humberto Llinás)* | **Avg (ms)**<br>**P95 (ms)**<br>**Throughput (req/s)**<br>**% Error**<br>**Muestras / Duración** | < 1 ms *(0 ms)*<br>1 ms<br>9687.30 req/s<br>**0.00 %**<br>*(581,231 / 60.0 s)* | 1 ms<br>2 ms<br>28433.10 req/s<br>**0.00 %**<br>*(1,706,100 / 60.0 s)* | 2 ms<br>4 ms<br>4426.88 req/s\*\*<br>**[Dato dudoso: listener acumulado]**<br>**0.00 %**<br>*(3,436,072 / 776.2 s)* | *(500 usuarios - Máx. probado, SIN fallo)\*<br>13 ms<br>20 ms<br>18969.14 req/s\*\*<br>**[Duración anómala]**<br>**0.00 %**<br>*(3,094,606 / 163.1 s)* |
| **Python (Flask + Gunicorn)**<br>*(Humberto Llinás)* | **Avg (ms)**<br>**P95 (ms)**<br>**Throughput (req/s)**<br>**% Error**<br>**Muestras / Duración** | 1 ms<br>3 ms<br>4864.85 req/s<br>**0.00 %**<br>*(291,896 / 60.0 s)* | 7 ms<br>11 ms<br>6251.37 req/s<br>**0.00 %**<br>*(375,145 / 60.0 s)* | 15 ms<br>20 ms<br>6232.49 req/s<br>**0.00 %**<br>*(374,074 / 60.0 s)* | *(500 usuarios - Máx. probado, SIN fallo)\*<br>85 ms<br>105 ms<br>5579.21 req/s<br>**0.00 %**<br>*(335,913 / 60.2 s)* |

---

### Notas Metodológicas Críticas sobre la Tabla Comparativa

1. **\*Diferencia entre Punto de Falla (Estrés) y Máximo Nivel Probado (Sin Fallo):**
   - Para **Node.js (1500 usuarios)** y **Java (1120 usuarios)**, la última columna representa un **punto de estrés y saturación empírico**. Ambos stacks fueron sometidos a barridos progresivos hasta detectar degradación severa y fallos medibles (0.80 % en Node por timeouts del cliente a 10 s; 0.19 % en Java por saturación del backlog de red en colima).
   - Para **Go (500 usuarios)** y **Python (500 usuarios)**, la fila representa exclusivamente el **máximo nivel probado en los archivos disponibles**, puesto que ambos finalizaron con **0.00 % de error**. No se realizó un barrido para hallar su punto de rotura o quiebre bajo estrés extremo; por tanto, esas filas no deben interpretarse como su límite de tolerancia a fallos.

2. **\*\*Inconsistencias de Duración y Listeners Acumulados en Go (`muestras / throughput`):**
   - En una corrida estándar de 60 segundos, la división de muestras entre el throughput debe arrojar aproximadamente 60 segundos. Esto se cumple con rigor en Node.js (59.9 a 63.0 s), Java (60.0 a 62.4 s) y Python (60.0 a 60.2 s).
   - En Go, las corridas de 10u (60.0 s) y 50u (60.0 s) son consistentes. Sin embargo, la corrida de **100 usuarios** duró en realidad **776.2 segundos** (3,436,072 muestras y 4,426.88 req/s con tamaño medio por petición anómalo de 2,268 bytes), la de **200 usuarios** duró **4,653.4 segundos** (3,474,840 muestras y 746.73 req/s), y la de **500 usuarios** duró **163.1 segundos** (3,094,606 muestras y 18,969.14 req/s). Esto demuestra que en JMeter no se reiniciaron los listeners entre pruebas, acumulándose datos de ejecuciones previas. Por este motivo, el dato de 100u de Go se cataloga formalmente como **"dato dudoso"** y no como corrida equivalente. Como referencia adicional, las pruebas intermedias de Go a 120, 140 y 160 usuarios sí duraron 60.0 s y marcaron de forma estable **~28,950 req/s** con P95 de 5-6 ms.

---

## 3. Consumo de Recursos del Sistema

Monitoreo promedio extraído mediante `docker stats` sobre el contenedor de la API y el contenedor de la base de datos PostgreSQL (`postgres:16`) durante las corridas de carga:

| Stack | Escenario | CPU API (%) | RAM API (MiB) | CPU DB (%) | RAM DB (MiB) | Observaciones de Comportamiento |
|---|---|---|---|---|---|---|
| **Node.js (NestJS)** | **Baja (10u)**<br>**Media (50u)**<br>**Alta (100u)**<br>**Estrés (1500u)** | 96.4 %<br>102.0 %<br>105.5 %<br>106.5 % | 66.4 MiB<br>104.8 MiB<br>99.3 MiB<br>160.2 MiB | 59.6 %<br>72.5 %<br>72.2 %<br>67.4 % | 94.8 MiB<br>135.2 MiB<br>139.7 MiB<br>142.9 MiB | Monohilo saturado al 100% de un núcleo desde 10 usuarios. Consumo de RAM moderado (<161 MiB). La base de datos nunca se saturó (máx 72% CPU). A 1500u se encolan peticiones causando timeouts de 10 s en el cliente. Cero errores 5xx. |
| **Java (Spring Boot)** | **Baja (10u)**<br>**Media (50u)**<br>**Alta (100u)**<br>**Estrés (1120u)** | 95.1 %<br>112.7 %<br>123.5 %<br>118.6 % | 320.0 MiB<br>320.3 MiB<br>365.8 MiB<br>524.4 MiB | 90.1 %<br>111.3 %<br>115.1 %<br>107.1 % | 216.1 MiB<br>221.3 MiB<br>229.2 MiB<br>232.9 MiB | Multihilo eficiente (Tomcat + HikariCP 30). Uso de RAM propio de JVM (arranca en ~320 MiB y sube a 524 MiB en estrés). CPU compartida en VM de 4 núcleos (colima). A 1120u falla el reenvío de red de la VM, no la JVM. |
| **Go (net/http + pgx)** | **Baja (10u)**<br>**Media (50u)**<br>**Alta (100u)**<br>**Máx. prob. (500u)** | 102.8 %<br>235.8 %<br>229.4 %<br>251.7 % | 21.6 MiB<br>28.2 MiB<br>30.4 MiB<br>42.4 MiB | 83.4 %<br>217.9 %<br>210.2 %<br>221.4 % | 214.9 MiB<br>277.5 MiB<br>279.9 MiB<br>283.1 MiB | Consumo de memoria mínimo (<43 MiB en máxima carga). Go y Postgres escalan aprovechando múltiples núcleos (>220% CPU). Entorno y condiciones de muestreo pendientes de confirmar con Humberto. |
| **Python (Flask + Gunicorn)** | **Baja (10u)**<br>**Media (50u)**<br>**Alta (100u)**<br>**Máx. prob. (500u)** | *No registrado*<br>*No registrado*<br>*No registrado*<br>*No registrado* | *No registrado*<br>*No registrado*<br>*No registrado*<br>*No registrado* | *No registrado*<br>*No registrado*<br>*No registrado*<br>*No registrado* | *No registrado*<br>*No registrado*<br>*No registrado*<br>*No registrado* | El autor del stack no registró ni conservó el archivo `resources_report.csv` para Python. La evidencia visual en `docker_ps.png` valida 4 workers Gunicorn con hilos, pero no hay métricas cuantitativas de CPU ni RAM. |

*\*Nota sobre Python y entorno de Humberto:* No existe archivo de consumo de recursos para Python en `docs/python/`. Asimismo, los detalles exactos del hardware, sistema operativo y versiones de Go/Python no se encuentran documentados en el repositorio y están pendientes de confirmación directa con el autor.

---

## 4. Respuestas a las 8 Conclusiones del Enunciado

> **Advertencia metodológica previa:** Los resultados no provienen de pruebas bajo condiciones homogéneas de laboratorio. Cada integrante ejecutó en su máquina física personal con procesadores y sistemas operativos distintos (Node.js en Ryzen 5 bajo Windows 11/WSL2; Java en Apple M1 bajo macOS con VM colima; Go y Python en hardware y SO no documentados). En consecuencia, las variaciones numéricas deben interpretarse con cautela y no como comparaciones estrictamente directas.

### Eje 1: Rendimiento

#### 1. ¿Cuál stack tuvo mejor latencia promedio?
En los datos registrados en el repositorio, **Go (net/http + pgx)** obtuvo la menor latencia promedio en todos los escenarios evaluados:
- A 10 usuarios: **< 1 ms (0 ms)**, frente a 1 ms de Python, 2 ms de Java y 14 ms de Node.js.
- A 50 usuarios: **1 ms**, frente a 7 ms de Python, 8 ms de Java y 62 ms de Node.js.
- A 100 usuarios: **2 ms**, frente a 15 ms de Python, 19 ms de Java y 125 ms de Node.js.
- En carga alta: **13 ms** (a 500 usuarios), frente a 85 ms de Python (500u), 337 ms de Java (1120u) y 2025 ms de Node.js (1500u).

Este rendimiento responde a su compilación nativa a binario de máquina, la bajísima sobrecarga de las *goroutines* y el uso del conector optimizado `pgx` con batching (`pgx.Batch`), reduciendo los viajes de red con PostgreSQL. No obstante, debe tenerse en cuenta que el entorno de ejecución de Go no fue documentado, lo que impide descartar ventajas de hardware respecto a los demás equipos.

#### 2. ¿Cuál mantuvo el mejor throughput en cargas altas?
**Go registró las tasas de procesamiento más elevadas:**
- Registró **28,433.10 req/s** a 50 usuarios y sostuvo **~28,950 req/s** en pruebas intermedias de 120-160 usuarios (el dato oficial a 100 usuarios fue de 4,426 req/s debido a acumulación en listeners).
- En segundo lugar se ubicó **Python (Flask + Gunicorn)**, con un throughput constante de **~6,200 req/s** (6,251.37 req/s a 50u, 6,232.49 req/s a 100u y 5,579.21 req/s a 500u), apalancado en 4 workers multihilo y pool de conexiones.
- En tercer lugar se situó **Java (Spring Boot)** con **5,226.93 req/s** a 50u y **4,683.21 req/s** a 100u, viéndose penalizado a cargas mayores por la capa de red de colima en macOS.
- **Node.js (NestJS)** presentó un techo temprano de **~730 req/s** (731.03 req/s a 50u y 727.54 req/s a 100u) debido a la saturación completa de su event loop monohilo en un único núcleo de CPU.

#### 3. ¿Qué lenguaje fue más estable?
**Go y Python demostraron alta estabilidad dentro del rango evaluado:**
- Ambos mantuvieron **0.00 % de error** en todas sus pruebas documentadas (desde 10 hasta 500 usuarios concurrentes).
- En dispersión de percentiles, Go mantuvo un P95 de **4 ms a 100 usuarios** y **20 ms a 500 usuarios**.
- Python mantuvo un P95 de **20 ms a 100 usuarios** y **105 ms a 500 usuarios** sin caídas de servicio.
- Java mantuvo 0.00 % de error y un P95 estable de **48 ms hasta 100 usuarios**, pero degradó al superar los 1000 usuarios debido a la limitación de sockets del proxy de virtualización colima en macOS.
- Node.js mantuvo 0.00 % de error hasta 100 usuarios, pero mostró un incremento lineal marcado en sus tiempos de respuesta (P95 de 27 ms a 10u, 84 ms a 50u, 163 ms a 100u y 2783 ms a 1500u), propio de un sistema encolado en un solo núcleo.

---

### Eje 2: Eficiencia

#### 4. ¿Algún stack mostró errores bajo alta carga?
**Sí, dos stacks presentaron errores al superar los 1,000 usuarios concurrentes:**
1. **Node.js (NestJS):** a **1500 usuarios concurrentes**, registró un **0.80 % de error** (**336** solicitudes fallidas de un total de **41,781** transacciones registradas en los 60 segundos de la corrida oficial).
2. **Java (Spring Boot):** a **1120 usuarios concurrentes**, registró un **0.19 % de error** (**354** conexiones rechazadas de un total de **184,477** transacciones registradas).
3. **Go y Python:** se probaron hasta 500 usuarios concurrentes y registraron **0.00 % de error** (cero fallos). Al no haberse sometido a cargas de saturación extrema ni haberse buscado su punto de rotura, no se observaron errores en las mediciones aportadas.

#### 5. ¿Qué puede explicar esas fallas?
El análisis técnico evidencia causas arquitectónicas y de infraestructura distintas:

1. **Causa en Node.js (NestJS) — Saturación del Event Loop monohilo:**
   - La totalidad de los 336 errores fueron de tipo `java.net.SocketTimeoutException: Read timed out` (configurado en 10 segundos en JMeter).
   - **No hubo un solo error HTTP 5xx ni falla en PostgreSQL:** la base de datos completó e insertó con integridad las 41,781 órdenes (41,445 atendidas dentro de los 10 s y 336 completadas tardíamente tras expirar el socket en el cliente).
   - La causa raíz radica en que Node.js procesa JavaScript en un único hilo. Aunque el acceso a PostgreSQL sea asíncrono, la serialización/deserialización de JSON, validaciones de clase en NestJS y acumulación de totales consumieron el **100 % de un núcleo de CPU** (106.5 % en docker stats). Ante 1500 clientes simultáneos, la cola de eventos en memoria superó los 10 segundos de demora, provocando el cierre de conexión por timeout del cliente.

2. **Causa en Java (Spring Boot) — Cuello de botella en la capa de red host-VM (macOS / colima):**
   - Los 354 errores en Java correspondieron a `org.apache.http.conn.HttpHostConnectException: Connect to localhost:5002 failed: Connection refused`.
   - **No hubo fallos en la JVM, ni presión del Garbage Collector, ni agotamiento del pool HikariCP:** la base de datos registró 184,228 pedidos almacenados transaccionalmente.
   - La falla se debió al puente de red de Docker en macOS (`colima` con `Virtualization.Framework`), donde el reenvío de puertos host-hacia-VM (`gvisor-tap-vsock`) saturó el backlog de conexiones TCP (`somaxconn` a nivel de SO en la VM) ante la ráfaga de 1120 sockets concurrentes. Pruebas directas con `ab` dentro de la propia VM confirmaron que la API atiende 1500 usuarios sin un solo error.

---

### Eje 3: Recomendación para Producción

#### 6. ¿Cuál stack recomendarían para una empresa que requiere alto desempeño?
**Recomendación técnica: Go (net/http + pgx)**.
- **Rendimiento:** Registró más de 28,000 req/s con latencias de 1-2 ms y P95 de 4 ms a 100 usuarios.
- **Eficiencia de costos en la nube:** Consume únicamente **~30-42 MiB de memoria RAM** bajo alta carga, frente a los ~365-524 MiB de Java o los ~160 MiB de Node.js. Esto permite una densidad de contenedores significativamente mayor por servidor físico, optimizando los costos de infraestructura.
- **Concurrencia nativa:** El modelo de *goroutines* maneja decenas de miles de conexiones con mínima sobrecarga de sistema operativo.
- *Consideración:* Se recomienda siempre que el equipo cuente con competencias en Go y se tenga en cuenta que las cifras provienen de un entorno no documentado. Como alternativa empresarial altamente consolidada, **Java 21 con Spring Boot 3.4** ofrece ~5,200 req/s, excelente soporte corporativo y pool `HikariCP` maduro.

#### 7. ¿Cuál stack es más fácil de implementar pero sacrifica rendimiento?
**Node.js con NestJS**.
- **Facilidad y Experiencia de Desarrollo (DX):** Proporciona un entorno estructurado y productivo gracias a TypeScript, decoradores, validación declarativa con DTOs e inyección de dependencias modular.
- **Sacrificio de rendimiento:** Su modelo monohilo por defecto impone un techo temprano de ~730 req/s:
  - Java a 50 usuarios alcanzó 5,226.93 req/s (**7.15 veces** el throughput de Node a la misma carga de 731.03 req/s).
  - Go a 50 usuarios alcanzó 28,433.10 req/s (**38.89 veces** el throughput de Node a la misma carga de 731.03 req/s).
  *(Nota: Se reitera que estas relaciones provienen de equipos con especificaciones técnicas distintas).*
- Para entornos de producción de alta concurrencia, Node.js exige de manera obligatoria implementar arquitectura de clúster (`pm2`, réplicas horizontales en Kubernetes y balanceadores NGINX/Envoy) para no desperdiciar la capacidad de los demás núcleos del servidor.

#### 8. ¿Cuál stack ofrece un mejor balance entre sencillez y velocidad?
**Python (Flask + Gunicorn con workers e hilos)**.
- **Sencillez:** El microservicio completo se implementó en únicamente **97 líneas de código en total** (`python/app.py` con 52 líneas y `python/database.py` con 45 líneas), sin necesidad de compilación ni configuraciones complejas de scaffolding.
- **Velocidad:** Con 4 workers multihilo y pool `psycopg_pool`, alcanzó **6,251.37 req/s a 50 usuarios** y **6,232.49 req/s a 100 usuarios** (representando **8.55 veces** y **8.57 veces** el throughput de Node a las mismas cargas, respectivamente) con latencias de 7 a 15 ms, ofreciendo un comportamiento balanceado sin la sobrecarga de memoria de la JVM.

---

## 5. Limitaciones Metodológicas del Estudio

Para una interpretación rigurosa de los resultados consolidados, deben considerarse las siguientes limitaciones:

1. **Heterogeneidad de hardware y sistemas operativos:**
   - Cada integrante evaluó en su propio equipo personal:
     - Node.js corrió en Windows 11 Pro con AMD Ryzen 5 8640HS (12 hilos, 36 GB RAM) sobre Docker en WSL2.
     - Java corrió en macOS Ventura con Apple Silicon M1 (8 núcleos, 8 GB RAM) sobre Docker en colima VM (4 vCPU, 3.8 GiB).
     - Go y Python corrieron en un entorno cuyas especificaciones de CPU, RAM, SO y versiones de runtime **no fueron documentadas** en el repositorio.
   - Las discrepancias numéricas reflejan tanto el rendimiento del stack de software como las diferencias de hardware, velocidad de memoria y capas de virtualización.

2. **Diferencias en la formalidad de entrega:**
   - Mientras que Node.js (`entrega-rafael-potes-node/`) y Java (`entrega-orlando-palma-java/`) entregaron informes estructurados (`INFORME.md`) y el set completo de 5 capturas oficiales por nivel (`docker_stats`, `htop`, `summary_report`, `aggregate_report`, `jmeter_ejecutando`), las carpetas `docs/go/` y `docs/python/` contienen únicamente datos preliminares sin informe formal ni capturas completas. Además, Python no incluye el archivo de consumo `resources_report.csv`.

3. **Inconsistencias de duración y listeners viciados en Go:**
   - Las corridas de 100u (776.2 s), 200u (4653.4 s) y 500u (163.1 s) de Go evidencian acumulación de muestras por falta de reinicio en los listeners de JMeter, por lo que deben interpretarse como datos dudosos frente a los 60 s estandarizados del resto de stacks.

4. **Ausencia de pruebas de estrés con punto de fallo en Go y Python:**
   - Go y Python se evaluaron únicamente hasta 500 usuarios, finalizando con 0.00 % de error. Al no haberse llevado hasta el punto de rotura empírico, no es posible comparar su comportamiento en saturación extrema con el de Node (1500u) y Java (1120u).

5. **Impacto de la virtualización de red en macOS:**
   - El reenvío de puertos de `colima` (`gvisor-tap-vsock`) generó un límite artificial de conexiones TCP en Java que no ocurre en entornos nativos de producción.

6. **Competición de recursos Host vs Cliente:**
   - En todos los casos, el generador de carga JMeter (con interfaz gráfica GUI) se ejecutó en la misma máquina física que los contenedores de la API y PostgreSQL, consumiendo recursos de CPU y memoria en paralelo con la aplicación bajo prueba.
