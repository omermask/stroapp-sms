FROM python:3.12-slim as builder

WORKDIR /app

RUN apt-get update && apt-get install -y gcc g++ libpq-dev && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

FROM python:3.12-slim as production

WORKDIR /app

RUN groupadd -r appuser && useradd -r -g appuser -d /home/appuser -m appuser

RUN apt-get update && apt-get install -y curl postgresql-client && rm -rf /var/lib/apt/lists/* && apt-get clean

COPY --from=builder /root/.local /home/appuser/.local

COPY --chown=appuser:appuser . .

ENV PATH=/home/appuser/.local/bin:$PATH
USER appuser

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:9527/stroapp/v1/health || exit 1

ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

EXPOSE 9527

CMD alembic upgrade head && gunicorn main:app -c gunicorn.conf.py
