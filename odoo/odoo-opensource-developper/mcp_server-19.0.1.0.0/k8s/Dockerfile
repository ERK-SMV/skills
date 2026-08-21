# Dockerfile for Odoo MCP Client
# Builds mcp-server-odoo Python package with dependencies
# Reference: mcp_server-19.0.1.0.0/README-Hermes.md

FROM python:3.11-slim as base

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install UV (faster pip alternative, required by mcp-server-odoo)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:${PATH}"

# Create and switch to app user
RUN useradd --create-home --shell /bin/bash appuser && \
    mkdir -p /app && \
    chown appuser:appuser /app
USER appuser
WORKDIR /app

# Stage 2: Build
FROM base as builder

# Copy mcp-server-odoo source
COPY mcp-client /app/mcp-server-odoo

# Install build dependencies
RUN pip install -U pip setuptools wheel

# Install mcp-server-odoo in editable mode
RUN cd /app/mcp-server-odoo && \
    pip install -e .[all]

# Stage 3: Production
FROM base as production

# Copy built package from builder
COPY --from=builder /app/mcp-server-odoo /app/mcp-server-odoo
COPY --from=builder /root/.local/bin/uvx /usr/local/bin/uvx
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages

# Install additional dependencies
RUN pip install --no-cache-dir \
    mcp \
    httpx \
    pydantic \
    python-multipart

# Set entrypoint
ENTRYPOINT ["mcp-server-odoo"]
CMD ["--transport", "stdio", "--config", "/app/config/mcp_config.json"]

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8000/mcp/health || exit 1
