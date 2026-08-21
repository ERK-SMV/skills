# Network Connectivity Debugging for Docker Services

## Common Network Connectivity Issues

### 1. Port Not Listening

**Symptoms:**
- Connection timeout when accessing service on specific port
- "Connection refused" or "Could not connect to server" errors
- Service appears to be running but port is not accessible

**Diagnosis:**
```bash
# Check if port is listening
curl -v http://localhost:8765

# Test with timeout to avoid long waits
curl -v --connect-timeout 10 http://localhost:8765

# Check if any process is listening on the port
# (Use appropriate command for your system)
ss -tlnp | grep 8765
netstat -tlnp | grep 8765
lsof -i :8765
```

### 2. Docker Container Network Issues

**Symptoms:**
- Container is running but service not accessible
- Port mapping issues
- DNS resolution problems within containers

**Diagnosis:**
```bash
# Check container port mappings
docker ps

# Inspect container network configuration
docker inspect container_name | grep -A 20 NetworkSettings

# Test connectivity from within container
docker exec -it container_name curl -v http://localhost:8765

# Test external connectivity from container
docker exec -it container_name curl -v http://registry.gitlab.akretion.com:8765
```

### 3. Registry Authentication Issues

**Symptoms:**
- "Unauthorized" errors when pulling images
- Authentication required errors
- Permission denied for private registries

**Solutions:**
```bash
# Login to private registry
docker login registry.gitlab.akretion.com

# Use proper image naming
docker pull registry.gitlab.akretion.com/akretion/fnfe/py3o-fnfe:0.10.0

# Check authentication tokens
cat ~/.docker/config.json
```

## Debugging Workflow

### Step 1: Verify Host Reachability
```bash
# Test basic connectivity to host
curl -v https://registry.gitlab.akretion.com

# Test specific port
curl -v http://registry.gitlab.akretion.com:8765
```

### Step 2: Check DNS Resolution
```bash
# Test DNS resolution
nslookup registry.gitlab.akretion.com
dig registry.gitlab.akretion.com

# Check /etc/hosts for manual entries
cat /etc/hosts | grep gitlab
```

### Step 3: Verify Port Accessibility
```bash
# Test port connectivity with timeout
curl -v --connect-timeout 10 http://registry.gitlab.akretion.com:8765

# Use telnet if available
telnet registry.gitlab.akretion.com 8765

# Use nc (netcat) if available
nc -zv registry.gitlab.akretion.com 8765
```

### Step 4: Check Firewall Rules
```bash
# Check iptables rules (Linux)
iptables -L -n

# Check ufw status (if using UFW)
sudo ufw status

# Check firewalld (if using firewalld)
sudo firewall-cmd --list-all
```

### Step 5: Verify Service Process
```bash
# Check if service process is running
ps aux | grep py3o
ps aux | grep 8765

# Check Docker processes
docker ps -a
docker ps | grep py3o
```

## Common Patterns

### Pattern: Service Not Running
**Issue:** Service process is not running
**Solution:** Start the service or container
```bash
# For Docker containers
docker-compose up -d
docker start container_name

# For system services
sudo systemctl start service_name
```

### Pattern: Wrong Port Mapping
**Issue:** Container port not mapped to host
**Solution:** Fix port mapping in docker-compose.yml
```yaml
services:
  py3o:
    image: registry.gitlab.akretion.com/akretion/fnfe/py3o-fnfe:0.10.0
    ports:
      - "8765:8765"  # Map host port 8765 to container port 8765
```

### Pattern: Firewall Blocking
**Issue:** Firewall blocking specific port
**Solution:** Add firewall rule
```bash
# Allow port 8765
sudo ufw allow 8765
sudo firewall-cmd --add-port=8765/tcp --permanent
sudo firewall-cmd --reload
```

### Pattern: Service Listening on Wrong Interface
**Issue:** Service listening only on localhost
**Solution:** Configure service to listen on all interfaces
```bash
# Check listening interfaces
ss -tlnp | grep 8765

# Should show 0.0.0.0:8765, not 127.0.0.1:8765
```

## Tools and Commands

### Basic Network Tools
```bash
# Test connectivity
curl -v http://host:port
wget -O- http://host:port

# Test port availability
telnet host port
nc -zv host port

# Check DNS
dig host
nslookup host
```

### Docker Network Tools
```bash
# List container networks
docker network ls

# Inspect network
docker network inspect network_name

# Test connectivity from container
docker exec -it container_name curl -v http://target:port

# Check container IP
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' container_name
```

### System Network Tools
```bash
# Check listening ports
ss -tlnp
netstat -tlnp
lsof -i

# Check routing table
ip route
route -n

# Check network interfaces
ip addr
ifconfig -a
```

## Case Study: py3o-fnfe Service Debugging

### Problem
- Service `registry.gitlab.akretion.com/akretion/fnfe/py3o-fnfe:0.10.0` not accessible on port 8765
- Connection timeout errors
- No supervisord configuration found

### Diagnosis Steps
1. **Verify host reachability:** ✅ Host reachable on port 443
2. **Test specific port:** ❌ Port 8765 connection timeout
3. **Check running processes:** ❌ No py3o/fnfe processes found
4. **Check Docker containers:** ❌ Docker not available
5. **Check supervisord:** ❌ No supervisord configuration found

### Root Cause
- Docker service not installed/running
- No container running the py3o service
- Missing supervisord configuration

### Solution
1. Install Docker
2. Pull the image: `docker pull registry.gitlab.akretion.com/akretion/fnfe/py3o-fnfe:0.10.0`
3. Run container with proper port mapping: `docker run -p 8765:8765 registry.gitlab.akretion.com/akretion/fnfe/py3o-fnfe:0.10.0`
4. Create supervisord configuration for process management