FROM python:3.12-slim

# Copia el binario oficial de uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    UV_COMPILE_BYTECODE=1

# Instala las dependencias directamente en el Python del sistema (mucho más rápido que pip)
COPY requirements.txt .
RUN uv pip install --system --no-cache -r requirements.txt

# Copia el código de la aplicación
COPY database.py app.py ./

EXPOSE 8080

CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "4", "--threads", "4", "app:app"]