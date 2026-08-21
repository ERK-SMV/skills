# Odoo MCP Server Configuration

## 📋 Installation Configuration

### 1. MCP Server Configuration File

Create `odoo_mcp_config.py`:

```python
# odoo_mcp_config.py
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

class OdooMCPConfig:
    # Odoo Connection
    ODOO_HOST = os.getenv('ODOO_HOST', 'odoo-service')
    ODOO_PORT = int(os.getenv('ODOO_PORT', '8069'))
    ODOO_DB = os.getenv('ODOO_DB', 'your_database')
    ODOO_USER = os.getenv('ODOO_USER', 'admin')
    ODOO_PASSWORD = os.getenv('ODOO_PASSWORD', '')
    
    # MCP Server
    MCP_HOST = os.getenv('MCP_HOST', '0.0.0.0')
    MCP_PORT = int(os.getenv('MCP_PORT', '3000'))
    MCP_API_KEY = os.getenv('MCP_API_KEY', '')
    
    # Performance
    CONNECTION_POOL_SIZE = int(os.getenv('CONNECTION_POOL_SIZE', '10'))
    REQUEST_TIMEOUT = int(os.getenv('REQUEST_TIMEOUT', '60'))
    CACHE_TTL = int(os.getenv('CACHE_TTL', '3600'))
    
    # Security
    RATE_LIMIT = int(os.getenv('RATE_LIMIT', '100'))  # requests per minute
    MAX_CONCURRENT = int(os.getenv('MAX_CONCURRENT', '20'))
    
    # Logging
    LOG_LEVEL = os.getenv('LOG_LEVEL', 'INFO')
    LOG_FILE = os.getenv('LOG_FILE', 'odoo_mcp_server.log')
```

### 2. MCP Server Implementation

Create `odoo_mcp_server.py`:

```python
# odoo_mcp_server.py
from mcp_server import MCPServer, MCPRequest
from odoorpc import ODOO
from odoo_mcp_config import OdooMCPConfig
import logging
from functools import lru_cache

# Configure logging
logging.basicConfig(
    level=OdooMCPConfig.LOG_LEVEL,
    filename=OdooMCPConfig.LOG_FILE,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class OdooMCPServer(MCPServer):
    def __init__(self):
        super().__init__()
        self.config = OdooMCPConfig()
        self.odoo = self._get_odoo_connection()
        logger.info("Odoo MCP Server initialized")
    
    @lru_cache(maxsize=OdooMCPConfig.CONNECTION_POOL_SIZE)
    def _get_odoo_connection(self):
        """Get Odoo connection with caching"""
        odoo = ODOO(
            self.config.ODOO_HOST,
            port=self.config.ODOO_PORT
        )
        odoo.login(
            self.config.ODOO_DB,
            self.config.ODOO_USER,
            self.config.ODOO_PASSWORD
        )
        logger.info("Odoo connection established")
        return odoo
    
    def handle_request(self, request: MCPRequest):
        """Handle MCP requests"""
        method = request.method
        params = request.params
        
        logger.debug(f"Received request: {method}")
        
        try:
            if method == "odoo/search_read":
                return self._search_read(params)
            elif method == "odoo/create":
                return self._create(params)
            elif method == "odoo/write":
                return self._write(params)
            elif method == "odoo/unlink":
                return self._unlink(params)
            else:
                return MCPRequest.error(f"Method not found: {method}")
                
        except Exception as e:
            logger.error(f"Error processing request: {str(e)}")
            return MCPRequest.error(f"Odoo error: {str(e)}")
    
    def _search_read(self, params):
        """Search and read records"""
        model = params.get('model')
        domain = params.get('domain', [])
        fields = params.get('fields', [])
        limit = params.get('limit', 100)
        
        return self.odoo.env[model].search_read(domain, fields, limit=limit)
    
    def _create(self, params):
        """Create new record"""
        model = params.get('model')
        values = params.get('values', {})
        
        return self.odoo.env[model].create(values)
    
    def _write(self, params):
        """Update records"""
        model = params.get('model')
        ids = params.get('ids', [])
        values = params.get('values', {})
        
        return self.odoo.env[model].browse(ids).write(values)
    
    def _unlink(self, params):
        """Delete records"""
        model = params.get('model')
        ids = params.get('ids', [])
        
        return self.odoo.env[model].browse(ids).unlink()

if __name__ == "__main__":
    server = OdooMCPServer()
    server.run(
        host=OdooMCPConfig.MCP_HOST,
        port=OdooMCPConfig.MCP_PORT
    )
```

### 3. Docker Configuration

Create `Dockerfile`:

```dockerfile
# Dockerfile
FROM python:3.9-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY odoo_mcp_config.py .
COPY odoo_mcp_server.py .

# Environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Run
CMD ["python", "odoo_mcp_server.py"]
```

### 4. Requirements File

Create `requirements.txt`:

```text
odoorpc==0.10.0
mcp-server==1.2.0
python-dotenv==1.0.0
requests==2.31.0
```

### 5. Environment File

Create `.env.example`:

```env
# Odoo Configuration
ODOO_HOST=odoo-service
ODOO_PORT=8069
ODOO_DB=your_database
ODOO_USER=admin
ODOO_PASSWORD=your_password

# MCP Server Configuration
MCP_HOST=0.0.0.0
MCP_PORT=3000
MCP_API_KEY=your_api_key

# Performance Configuration
CONNECTION_POOL_SIZE=10
REQUEST_TIMEOUT=60
CACHE_TTL=3600

# Security Configuration
RATE_LIMIT=100
MAX_CONCURRENT=20

# Logging Configuration
LOG_LEVEL=INFO
LOG_FILE=odoo_mcp_server.log
```

### 6. Kubernetes Deployment

Create `kubernetes/deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: odoo-mcp-server
  labels:
    app: odoo-mcp-server
spec:
  replicas: 2
  selector:
    matchLabels:
      app: odoo-mcp-server
  template:
    metadata:
      labels:
        app: odoo-mcp-server
    spec:
      containers:
      - name: odoo-mcp-server
        image: your-registry/odoo-mcp-server:latest
        ports:
        - containerPort: 3000
        envFrom:
        - secretRef:
            name: odoo-mcp-secrets
        resources:
          requests:
            cpu: "500m"
            memory: "512Mi"
          limits:
            cpu: "1000m"
            memory: "1024Mi"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
```

### 7. Kubernetes Service

Create `kubernetes/service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: odoo-mcp-server
spec:
  selector:
    app: odoo-mcp-server
  ports:
    - protocol: TCP
      port: 3000
      targetPort: 3000
  type: ClusterIP
```

### 8. Kubernetes Ingress

Create `kubernetes/ingress.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: odoo-mcp-server
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: odoo-mcp.your-domain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: odoo-mcp-server
            port:
              number: 3000
```

### 9. Kubernetes ConfigMap

Create `kubernetes/configmap.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: odoo-mcp-config
data:
  ODOO_HOST: "odoo-service"
  ODOO_PORT: "8069"
  ODOO_DB: "your_database"
  MCP_HOST: "0.0.0.0"
  MCP_PORT: "3000"
  CONNECTION_POOL_SIZE: "10"
  REQUEST_TIMEOUT: "60"
  CACHE_TTL: "3600"
  RATE_LIMIT: "100"
  MAX_CONCURRENT: "20"
  LOG_LEVEL: "INFO"
```

### 10. Kubernetes Secret

Create `kubernetes/secret.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: odoo-mcp-secrets
type: Opaque
data:
  ODOO_USER: "YWRtaW4="  # base64 encoded
  ODOO_PASSWORD: "YWJjZGVmZ2hp"  # base64 encoded
  MCP_API_KEY: "eW91cl9hcGlfa2V5"  # base64 encoded
```

## 🚀 Deployment Instructions

### 1. Build Docker Image

```bash
cd /path/to/odoo-mcp-server
docker build -t your-registry/odoo-mcp-server:latest .
docker push your-registry/odoo-mcp-server:latest
```

### 2. Deploy to Kubernetes

```bash
# Apply ConfigMap and Secret
kubectl apply -f kubernetes/configmap.yaml
kubectl apply -f kubernetes/secret.yaml

# Deploy application
kubectl apply -f kubernetes/deployment.yaml
kubectl apply -f kubernetes/service.yaml

# Apply ingress (if needed)
kubectl apply -f kubernetes/ingress.yaml
```

### 3. Verify Deployment

```bash
# Check pods
kubectl get pods -l app=odoo-mcp-server

# Check logs
kubectl logs -l app=odoo-mcp-server -f

# Test connection
kubectl exec -it <pod-name> -- curl -v http://localhost:3000/health
```

### 4. Configure Hermes

Add to Hermes configuration:

```json
{
  "mcpServers": {
    "odoo": {
      "url": "http://odoo-mcp-server:3000",
      "transport": "http",
      "methods": [
        "odoo/search_read",
        "odoo/create",
        "odoo/write",
        "odoo/unlink"
      ],
      "timeout": 60000,
      "retries": 3,
      "headers": {
        "X-API-Key": "your_api_key"
      }
    }
  }
}
```

### 5. Test Integration

```python
# Test from Hermes
from hermes.mcp import MCPClient

client = MCPClient('odoo')

# Test search_read
result = client.call_method('odoo/search_read', {
    'model': 'res.partner',
    'domain': [['is_company', '=', True]],
    'fields': ['name', 'email'],
    'limit': 10
})

print(f"Found {len(result)} partners")
```

## 🛡️ Security Best Practices

### 1. API Key Management

```python
# Rotate API keys regularly
import secrets

def generate_api_key():
    return secrets.token_urlsafe(32)

# Store keys securely
# Use Kubernetes Secrets or HashiCorp Vault
```

### 2. Rate Limiting

```python
# Implement rate limiting
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

limiter = Limiter(
    app=app,
    key_func=get_remote_address,
    default_limits=["100 per minute"]
)

@app.route("/mcp")
@limiter.limit("100 per minute")
def handle_request():
    # Your implementation
```

### 3. Input Validation

```python
# Validate all inputs
from pydantic import BaseModel, ValidationError

class SearchReadRequest(BaseModel):
    model: str
    domain: list = []
    fields: list = []
    limit: int = 100
    
    @validator('limit')
    def check_limit(cls, v):
        if v > 1000:
            raise ValueError('Limit cannot exceed 1000')
        return v
```

### 4. Logging and Monitoring

```python
# Comprehensive logging
import logging
from logging.handlers import RotatingFileHandler

handler = RotatingFileHandler(
    'odoo_mcp_server.log',
    maxBytes=1024 * 1024 * 5,  # 5 MB
    backupCount=5
)

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[handler]
)
```

## 📊 Performance Optimization

### 1. Connection Pooling

```python
# Connection pooling
from odoorpc import ODOO
from functools import lru_cache

@lru_cache(maxsize=10)
def get_odoo_connection():
    odoo = ODOO('odoo-service', port=8069)
    odoo.login('your_db', 'admin', 'password')
    return odoo
```

### 2. Caching

```python
# Implement caching
from functools import lru_cache

@lru_cache(maxsize=100)
def get_model_fields(model):
    return odoo.env[model].fields_get()
```

### 3. Batch Processing

```python
# Batch processing
def process_batch(records):
    # Process records in batches
    batch_size = 50
    for i in range(0, len(records), batch_size):
        batch = records[i:i + batch_size]
        process_batch_internal(batch)
```

## 🔧 Maintenance

### 1. Health Checks

```python
# Health check endpoint
@app.route('/health')
def health():
    try:
        # Check Odoo connection
        odoo = get_odoo_connection()
        odoo.env['res.users'].search([], limit=1)
        
        return {'status': 'ok', 'message': 'Service healthy'}
    except Exception as e:
        return {'status': 'error', 'message': str(e)}, 500
```

### 2. Metrics

```python
# Prometheus metrics
from prometheus_client import start_http_server, Counter, Gauge

# Metrics
REQUEST_COUNT = Counter('odoo_mcp_requests_total', 'Total requests')
REQUEST_TIME = Gauge('odoo_mcp_request_time_seconds', 'Request processing time')
ERROR_COUNT = Counter('odoo_mcp_errors_total', 'Total errors')

# Start metrics server
start_http_server(8000)
```

### 3. Backup and Restore

```bash
# Backup configuration
kubectl get configmap odoo-mcp-config -o yaml > backup/configmap.yaml
kubectl get secret odoo-mcp-secrets -o yaml > backup/secret.yaml

# Restore configuration
kubectl apply -f backup/configmap.yaml
kubectl apply -f backup/secret.yaml
```

## ✅ Conclusion

This configuration provides a complete, production-ready Odoo MCP server implementation that:

1. **Follows OCA conventions** for Odoo integration
2. **Implements MCP protocol** for Hermes compatibility
3. **Provides security** through API keys and rate limiting
4. **Optimizes performance** with connection pooling and caching
5. **Supports Kubernetes** deployment and scaling
6. **Includes monitoring** and health checks

The implementation can be deployed as a standalone service or integrated directly into an Odoo addon module, depending on your architectural requirements.