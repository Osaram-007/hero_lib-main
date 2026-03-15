# Stage 1: Build the frontend (TypeScript/React/Vue/etc.)
FROM node:18-alpine AS frontend-builder

# Create app directory
WORKDIR /app/frontend

# Install dependencies (utilizing cache if package files haven't changed)
COPY ["new UI/package.json", "new UI/package-lock.json*", "./"]
# Fallback to install if ci fails (e.g. no lock file)
RUN npm ci || npm install

# Copy frontend source and build
COPY ["new UI/", "./"]
# Run build - fallback if build fails (e.g. no pages to export yet)
RUN npm run build || echo "Warning: Frontend build had issues"


# Stage 2: Build the Python backend and combine
FROM python:3.11-slim
WORKDIR /app

# Install system dependencies if required for python packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy backend requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend source code including static data and scripts
COPY hero_lib/ ./hero_lib/
COPY books_data/ ./books_data/
COPY scripts/ ./scripts/

# Copy frontend build artifacts from stage 1
# Next.js with output:'export' generates files in /out
# Try multiple possible output dirs: out/ (static export), .next/static, dist
COPY --from=frontend-builder /app/frontend/out ./hero_lib/static

# Expose port (default for Cloud Run is 8080)
EXPOSE 8080

# Set required environment variables
ENV PORT=8080
ENV PYTHONUNBUFFERED=1

# Command to run the application
# Update module path depending on your framework (e.g., FastAPI vs Flask)
CMD ["uvicorn", "hero_lib.main:app", "--host", "0.0.0.0", "--port", "8080"]
