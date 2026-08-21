# Odoo Port Conflict Patterns

## Common Port Conflict Scenarios

### Scenario 1: Multiple Odoo Instances
**Symptoms:**
- Second Odoo instance fails to start
- "Address already in use" error
- First instance works fine

**Solution:**
```bash
# Option 1: Use different ports
# Edit docker-compose.yml for second instance
ports:
  - "8070:8069"

# Option 2: Stop first instance
docker-compose -f first-compose.yml down
```

### Scenario 2: Stale Docker Container
**Symptoms:**
- Container shows as stopped but port still in use
- `docker ps` doesn't show running container
- Port conflict persists after `docker-compose down`

**Solution:**
```bash
# Remove all containers
docker rm -f $(docker ps -aq)

# Clean up networks
docker network prune

# Restart
docker-compose up -d
```

### Scenario 3: Host Process Conflict
**Symptoms:**
- Non-Docker process using port 8069
- `docker ps` shows no containers
- `ps aux | grep 8069` shows processes

**Solution:**
```bash
# Find and kill processes
pkill -f 8069

# Or more specifically
kill -9 $(ps aux | grep 8069 | awk '{print $2}')
```

## Diagnostic Commands

### Basic Checks
```bash
# Check listening ports
ss -tuln | grep 8069

# Check Docker containers
docker ps

# Check all processes
ps aux | grep 8069
```

### Advanced Diagnostics
```bash
# Check socket connections
netstat -tuln | grep 8069

# Check Docker network usage
docker network inspect bridge

# Check iptables (if using Docker with iptables)
iptables -t nat -L -n | grep 8069
```

## Prevention Strategies

### Port Management
- Use port ranges: 8069, 8070, 8071 for multiple instances
- Document port assignments
- Use environment variables for port configuration

### Docker Best Practices
```yaml
# Example docker-compose.yml with port management
version: '3'
services:
  odoo1:
    image: odoo:14.0
    ports:
      - "8069:8069"
    environment:
      - ODOO_PORT=8069
  
  odoo2:
    image: odoo:14.0
    ports:
      - "8070:8069"
    environment:
      - ODOO_PORT=8069
```

### Cleanup Routine
```bash
# Daily cleanup script
#!/bin/bash

# Remove exited containers
docker rm -f $(docker ps -aq -f status=exited)

# Remove dangling images
docker image prune -f

# Remove unused networks
docker network prune -f
```

## Error Message Patterns

### Pattern 1: Direct Port Conflict
```
Error: Address already in use
Bind for 0.0.0.0:8069 failed: port is already allocated
```

### Pattern 2: Docker Network Conflict
```
Error creating network: pool overlaps with other one
Error starting userland proxy: listen tcp 0.0.0.0:8069: bind: address already in use
```

### Pattern 3: Socket Binding Failure
```
socket.error: [Errno 98] Address already in use
OSError: [Errno 98] Address already in use
```

## Resolution Workflow

1. **Identify conflict source:**
   - `docker ps` (Docker containers)
   - `ps aux | grep 8069` (Host processes)
   - `ss -tuln | grep 8069` (Listening sockets)

2. **Resolve conflict:**
   - Docker: `docker-compose down && docker rm -f container_id`
   - Host: `kill -9 process_id`
   - Network: `docker network prune`

3. **Verify resolution:**
   - `ss -tuln | grep 8069` (should return nothing)
   - `docker ps` (should show no conflicting containers)

4. **Restart Odoo:**
   - `docker-compose up -d`
   - Verify with `docker logs container_id`

5. **Update modules:**
   - `docker-compose exec odoo odoo-bin -u your_module -d db_name`