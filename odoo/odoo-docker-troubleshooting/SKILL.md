---
name: odoo-docker-troubleshooting
description: Resolve Odoo Docker port conflicts and module update issues.
version: 1.0.0
author: Hermes Agent
tags: [odoo, docker, troubleshooting, port-conflict, module-update]
---

# Odoo Docker Troubleshooting

Expert guide for resolving common Odoo Docker issues, particularly "Address already in use" errors and module update problems.

## Scope

Use this skill when encountering:
- Port conflicts ("Address already in use" errors)
- Module update failures in Docker
- Container startup issues
- Docker-specific Odoo problems

## Common Issues and Solutions

### 1. "Address already in use" Error (Port 8069)

**Symptoms:**
- Odoo container fails to start
- Error message: "Address already in use"
- Typically on port 8069

**Diagnosis:**
```bash
# Check for processes using port 8069
ps aux | grep 8069

# Check Docker containers
docker ps
```

**Solutions:**

#### Solution A: Kill conflicting processes
```bash
# Find process IDs using port 8069
for pid in $(ps aux | awk '/8069/ {print $2}'); do
    echo "Killing process $pid"
    kill -9 $pid
 done
```

#### Solution B: Docker cleanup
```bash
# Stop all containers
docker-compose down

# Remove containers
docker-compose rm -f

# Remove any stale networks
docker network prune

# Restart fresh
docker-compose up -d
```

#### Solution C: Change Odoo port
Edit your `docker-compose.yml`:
```yaml
ports:
  - "8070:8069"  # Map host port 8070 to container port 8069
```

### 2. Module Update Issues

**Update module list:**
```bash
docker-compose exec odoo odoo-bin -u all -d your_database_name --stop-after-init
```

**Install specific module:**
```bash
docker-compose exec odoo odoo-bin -i your_module_name -d your_database_name --stop-after-init
```

**Using odoo-click-update:**
```bash
docker-compose exec odoo odoo-click-update -d your_database_name -m your_module_name
```

### 3. Container Management

**Restart Odoo container:**
```bash
docker-compose restart odoo
```

**View logs:**
```bash
docker-compose logs -f odoo
```

**Enter container shell:**
```bash
docker-compose exec odoo bash
```

## Advanced Troubleshooting

### Port Conflict Diagnosis
```bash
# List all listening ports
ss -tuln | grep 8069

# Find which process is using the port
lsof -i :8069

# If lsof not available
netstat -tuln | grep 8069
```

### Docker Network Issues
```bash
# List all networks
docker network ls

# Inspect specific network
docker network inspect network_name

# Clean up unused networks
docker network prune
```

### Volume Permissions
```bash
# Fix volume permissions
chown -R odoo:odoo /path/to/addons
chmod -R 755 /path/to/addons
```

## Best Practices

1. **Always check logs first:**
   ```bash
   docker-compose logs -f odoo
   ```

2. **Use specific module updates:**
   ```bash
   docker-compose exec odoo odoo-bin -u your_module -d db_name
   ```

3. **Clean restart pattern:**
   ```bash
   docker-compose down
   docker-compose rm -f
   docker-compose up -d
   ```

4. **Port mapping strategy:**
   - Use different host ports for multiple instances
   - Document port mappings in your compose file
   - Avoid port conflicts with other services

## Network Connectivity Debugging

### Common Network Issues

#### 1. External Registry Connectivity

**Symptoms:**
- Connection timeouts to external registries
- "Could not connect to server" errors
- Port-specific connectivity issues

**Diagnosis:**
```bash
# Test basic host connectivity
curl -v https://registry.gitlab.akretion.com

# Test specific port
curl -v --connect-timeout 10 http://registry.gitlab.akretion.com:8765

# Check DNS resolution
nslookup registry.gitlab.akretion.com
```

**Solutions:**
- Verify the service is running on the target port
- Check firewall rules
- Test from within containers if applicable
- Verify Docker network configuration

#### 2. Docker Network Issues

**Symptoms:**
- Containers can't communicate with each other
- External services not accessible from containers
- Port mapping not working

**Diagnosis:**
```bash
# Check container network settings
docker inspect container_name | grep NetworkSettings

# Test connectivity from within container
docker exec -it container_name curl -v http://target_service:port

# Check port mappings
docker ps
```

**Solutions:**
- Verify port mappings in docker-compose.yml
- Check Docker network configuration
- Test connectivity between containers

### Network Debugging Workflow

1. **Test basic connectivity** to the host
2. **Check DNS resolution** for the target hostname
3. **Test specific port** with timeout to avoid long waits
4. **Check firewall rules** that might block the port
5. **Verify service processes** are running and listening
6. **Test from within containers** if applicable

See [Network Connectivity Debugging](references/network-connectivity-debugging.md) for detailed patterns and case studies.

### Pattern 2: Database Lock
**Error:** Database locked or in use
**Solution:**
```bash
# Stop all Odoo processes
pkill -f odoo

# Restart PostgreSQL if needed
docker-compose restart postgres
```

### Pattern 3: Module Not Found
**Error:** Module not appearing in Apps menu
**Solution:**
```bash
# Update module list
docker-compose exec odoo odoo-bin -u all -d db_name

# Check module path configuration
# Ensure your addons directory is mounted correctly
```

## Reference Commands

**Basic Docker commands:**
```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View running containers
docker ps

# View all containers (including stopped)
docker ps -a

# Remove specific container
docker rm container_name

# Remove all stopped containers
docker container prune
```

**Odoo-specific commands:**
```bash
# Update all modules
docker-compose exec odoo odoo-bin -u all -d db_name

# Install specific module
docker-compose exec odoo odoo-bin -i module_name -d db_name

# Run shell commands
docker-compose exec odoo odoo-bin shell -d db_name

# Test database connection
docker-compose exec postgres psql -U odoo -d postgres
```

## Troubleshooting Workflow

1. **Check logs:** `docker-compose logs -f odoo`
2. **Verify port usage:** `ss -tuln | grep 8069`
3. **Test network connectivity:** `curl -v http://host:port`
4. **Kill conflicting processes:** `pkill -f 8069`
5. **Clean restart:** `docker-compose down && docker-compose up -d`
6. **Update modules:** `docker-compose exec odoo odoo-bin -u your_module -d db_name`
7. **Check container health:** `docker ps`
8. **Verify DNS resolution:** `nslookup hostname`
9. **Check firewall rules:** `iptables -L -n`

## References

- [Port Conflict Patterns](references/port-conflict-patterns.md) - Common port conflict scenarios and solutions
- [Network Connectivity Debugging](references/network-connectivity-debugging.md) - Network troubleshooting for Docker services and external registries

## Pitfalls

- **Don't kill PostgreSQL processes** - Only kill Odoo-related processes
- **Backup before pruning** - `docker system df` before running `prune` commands
- **Check volume mounts** - Ensure addons directories are properly mounted
- **Port mapping conflicts** - Don't map multiple containers to the same host port
- **Database compatibility** - Ensure Odoo version matches database schema version