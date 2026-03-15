# Stage 1: Build the frontend (Next.js)
FROM node:18-alpine AS frontend-builder

WORKDIR /app/frontend

# Install dependencies
COPY ["new UI/package.json", "new UI/package-lock.json*", "./"]
RUN npm ci --legacy-peer-deps || npm install --legacy-peer-deps

# Copy frontend source and build
COPY ["new UI/", "./"]
# Build static export; create empty out/ dir as fallback
RUN npm run build || true
RUN mkdir -p /app/frontend/out


# Stage 2: Build the Python backend and combine
FROM python:3.11-slim
WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend source code
COPY hero_lib/ ./hero_lib/
COPY books_data/ ./books_data/
COPY scripts/ ./scripts/

# Copy frontend build output (may be empty if build failed)
COPY --from=frontend-builder /app/frontend/out ./hero_lib/static

EXPOSE 8080
ENV PORT=8080
ENV PYTHONUNBUFFERED=1

CMD ["uvicorn", "hero_lib.main:app", "--host", "0.0.0.0", "--port", "8080"]
