# SSH Diagnostic Commands and Scripts

## Basic SSH Diagnostics

### Check SSH Agent Status
```bash
#!/bin/bash
# ssh-agent-status.sh
echo "=== SSH Agent Status ==="
echo "SSH_AUTH_SOCK: $SSH_AUTH_SOCK"
echo "SSH_AGENT_PID: $SSH_AGENT_PID"

if [ -z "$SSH_AUTH_SOCK" ]; then
    echo "SSH agent not running"
else
    echo "SSH agent running"
    if [ -e "$SSH_AUTH_SOCK" ]; then
        echo "Socket file exists"
        ls -la "$SSH_AUTH_SOCK"
    else
        echo "Socket file not found"
    fi
fi

# Check running processes
ps aux | grep ssh-agent | grep -v grep
```

### Test SSH Connections
```bash
#!/bin/bash
# test-ssh-connections.sh
echo "=== Testing SSH Connections ==="

# Test GitHub
secho "Testing GitHub SSH..."
ssh -T git@github.com 2>&1 | head -5

# Test GitLab
echo "Testing GitLab SSH..."
ssh -T git@gitlab.com 2>&1 | head -5

# Test with verbose output
echo "Testing GitHub with verbose..."
ssh -vvv git@github.com 2>&1 | grep -A5 "debug1:"
```

### Check Directory Permissions
```bash
#!/bin/bash
# check-permissions.sh
echo "=== Directory Permissions ==="
echo "Home directory:"
ls -ld ~

echo "SSH directory:"
ls -ld ~/.ssh

echo "SSH keys:"
ls -la ~/.ssh/id_* 2>/dev/null || echo "No SSH keys found"

echo "/tmp directory:"
ls -ld /tmp

echo "Current user:"
whoami
echo "User groups:"
groups
```

## Advanced Diagnostics

### SSH Key Validation
```bash
#!/bin/bash
# validate-ssh-keys.sh
echo "=== SSH Key Validation ==="

for key in ~/.ssh/id_*; do
    if [ -f "$key" ]; then
        echo "Checking $key:"
        file "$key"
        ls -la "$key"
        
        # Check if private key
        if [[ "$key" != *".pub" ]]; then
            echo "Private key permissions:"
            stat -c "%a %n" "$key"
            
            # Check if too permissive
            perms=$(stat -c "%a" "$key")
            if [ "$perms" != "600" ]; then
                echo "WARNING: Key permissions should be 600"
            fi
        fi
        echo
    fi
done
```

### Git Clone Testing
```bash
#!/bin/bash
# test-git-clone.sh
echo "=== Git Clone Testing ==="

# Test SSH clone
echo "Testing SSH clone..."
GIT_SSH_COMMAND='ssh -v' timeout 10 git clone git@github.com:akretion/test-repo.git test-ssh-clone 2>&1 | head -20
rm -rf test-ssh-clone

# Test HTTPS clone
echo "Testing HTTPS clone..."
timeout 10 git clone https://github.com/akretion/test-repo.git test-https-clone 2>&1 | head -20
rm -rf test-https-clone
```

### SSH Config Validation
```bash
#!/bin/bash
# validate-ssh-config.sh
echo "=== SSH Config Validation ==="

if [ -f ~/.ssh/config ]; then
    echo "SSH config file exists:"
    cat ~/.ssh/config
    
    echo "Validating config..."
    ssh -G git@github.com 2>&1 || echo "Config validation failed"
else
    echo "No SSH config file found"
fi
```

## Troubleshooting Scripts

### Fix SSH Permissions
```bash
#!/bin/bash
# fix-ssh-permissions.sh
echo "=== Fixing SSH Permissions ==="

# Fix .ssh directory
chmod 700 ~/.ssh
echo "Fixed .ssh directory permissions"

# Fix private keys
for key in ~/.ssh/id_* ~/.ssh/*_rsa ~/.ssh/*_dsa ~/.ssh/*_ecdsa ~/.ssh/*_ed25519; do
    if [ -f "$key" ] && [[ "$key" != *".pub" ]]; then
        chmod 600 "$key"
        echo "Fixed permissions for $key"
    fi
done

# Fix public keys
for key in ~/.ssh/*.pub; do
    if [ -f "$key" ]; then
        chmod 644 "$key"
        echo "Fixed permissions for $key"
    fi
done

# Fix known_hosts
if [ -f ~/.ssh/known_hosts ]; then
    chmod 644 ~/.ssh/known_hosts
    echo "Fixed known_hosts permissions"
fi

# Fix authorized_keys
if [ -f ~/.ssh/authorized_keys ]; then
    chmod 600 ~/.ssh/authorized_keys
    echo "Fixed authorized_keys permissions"
fi

echo "SSH permissions fixed"
```

### Start SSH Agent with Custom Socket
```bash
#!/bin/bash
# start-custom-ssh-agent.sh
echo "=== Starting SSH Agent with Custom Socket ==="

# Create socket directory
mkdir -p ~/.ssh/sockets
chmod 700 ~/.ssh/sockets

# Set socket path
export SSH_AUTH_SOCK=~/.ssh/sockets/ssh_auth_sock

# Start agent
ssh-agent -a $SSH_AUTH_SOCK

# Add keys
for key in ~/.ssh/id_* ~/.ssh/*_rsa ~/.ssh/*_dsa ~/.ssh/*_ecdsa ~/.ssh/*_ed25519; do
    if [ -f "$key" ] && [[ "$key" != *".pub" ]]; then
        ssh-add "$key"
        echo "Added $key to SSH agent"
    fi
done

# Show agent info
ssh-add -l
```

### Test Copier with Different Methods
```bash
#!/bin/bash
# test-copier-methods.sh
echo "=== Testing Copier Methods ==="

# Method 1: HTTPS with token (replace with actual token)
echo "Method 1: HTTPS with token"
export COPIER_HTTPS_TOKEN="your_token_here"
copier copy https://oauth2:$COPIER_HTTPS_TOKEN@github.com/akretion/docky-odoo-template-shared ./test-copier-https 2>&1 | head -10

# Method 2: Local clone
echo "Method 2: Local clone"
git clone https://github.com/akretion/docky-odoo-template-shared.git ./test-copier-local
copier copy ./test-copier-local ./test-copier-local-copy 2>&1 | head -10

# Method 3: Different TMPDIR
echo "Method 3: Different TMPDIR"
export TMPDIR=$HOME/tmp
mkdir -p $TMPDIR
copier copy https://github.com/akretion/docky-odoo-template-shared ./test-copier-tmpdir 2>&1 | head -10

# Cleanup
rm -rf ./test-copier-https ./test-copier-local ./test-copier-local-copy ./test-copier-tmpdir
```

## Monitoring Scripts

### SSH Agent Monitor
```bash
#!/bin/bash
# monitor-ssh-agent.sh
echo "=== SSH Agent Monitor ==="

while true; do
    clear
    echo "SSH Agent Status: $(date)"
    echo "================================"
    
    if [ -z "$SSH_AUTH_SOCK" ]; then
        echo "SSH agent: NOT RUNNING"
    else
        echo "SSH agent: RUNNING"
        echo "Socket: $SSH_AUTH_SOCK"
        
        if [ -e "$SSH_AUTH_SOCK" ]; then
            echo "Socket file: EXISTS"
            echo "Keys loaded: $(ssh-add -l 2>/dev/null | wc -l)"
        else
            echo "Socket file: NOT FOUND"
        fi
    fi
    
    echo ""
    echo "SSH processes:"
    ps aux | grep ssh | grep -v grep
    
    sleep 5
done
```

### Git Operation Monitor
```bash
#!/bin/bash
# monitor-git-operations.sh
echo "=== Git Operation Monitor ==="

# Monitor git operations
while true; do
    clear
    echo "Git Operations: $(date)"
    echo "================================"
    
    # Show recent git processes
    echo "Recent git processes:"
    ps aux | grep git | grep -v grep | tail -5
    
    # Show git network activity
    echo "Git network activity:"
    sudo lsof -i | grep git | tail -5
    
    # Show git lock files
    echo "Git lock files:"
    find /tmp -name ".git*" -type f 2>/dev/null | tail -5
    
    sleep 3
done
```

## Usage Examples

### Basic Diagnosis
```bash
# Run all basic diagnostics
./check-permissions.sh
./validate-ssh-keys.sh
./test-ssh-connections.sh
```

### Fix and Restart
```bash
# Fix permissions and restart agent
./fix-ssh-permissions.sh
./start-custom-ssh-agent.sh
```

### Monitor Operations
```bash
# Monitor SSH agent in background
./monitor-ssh-agent.sh &

# Monitor git operations
./monitor-git-operations.sh &
```

## Script Reference

| Script | Purpose |
|--------|---------|
| `ssh-agent-status.sh` | Check SSH agent status |
| `test-ssh-connections.sh` | Test SSH connections |
| `check-permissions.sh` | Check directory permissions |
| `validate-ssh-keys.sh` | Validate SSH key permissions |
| `test-git-clone.sh` | Test git clone methods |
| `validate-ssh-config.sh` | Validate SSH config |
| `fix-ssh-permissions.sh` | Fix SSH permissions |
| `start-custom-ssh-agent.sh` | Start SSH agent with custom socket |
| `test-copier-methods.sh` | Test copier methods |
| `monitor-ssh-agent.sh` | Monitor SSH agent |
| `monitor-git-operations.sh` | Monitor git operations |

## Best Practices

1. **Run diagnostics first** before making changes
2. **Use custom socket locations** in restricted environments
3. **Test with verbose output** to identify issues
4. **Monitor operations** during troubleshooting
5. **Document fixes** for future reference

## Session-Specific Scripts

### ITIPART Docky Setup Script
```bash
#!/bin/bash
# itipart-docky-setup.sh
echo "=== ITIPART Docky Setup ==="

# Create structure
mkdir -p odoo/{local-src,patches} backup bin

# Create Dockerfile
cat > odoo/Dockerfile << 'EOF'
FROM ghcr.io/akretion/odoo-docker:18.0-light-latest as base
FROM base as thisproject
USER root
RUN apt-get update && apt-get install -y build-essential python3-dev
COPY odoo/requirements.txt /requirements.txt
RUN pip install -r /requirements.txt
FROM thisproject as test
USER odoo
COPY --chown=odoo:odoo odoo/ /odoo
RUN /odoo/odoo-bin -i base -d test --without-demo=ALL --stop-after-init
FROM thisproject as prod
USER odoo
COPY --chown=odoo:odoo odoo/ /odoo
RUN /odoo/odoo-bin -i base -d prod --without-demo=ALL --stop-after-init
CMD ["/odoo/odoo-bin"]
EOF

# Create docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  odoo:
    build:
      context: .
      dockerfile: odoo/Dockerfile
      target: thisproject
    image: itipart-odoo:latest
    container_name: itipart-odoo
    environment:
      - HOST=localhost
      - USER=admin
      - PASSWORD=admin
      - PGDATABASE=postgres
      - PGHOST=db
      - PGPORT=5432
      - PGUSER=odoo
    depends_on:
      - db
    ports:
      - "8069:8069"
    volumes:
      - odoo-data:/var/lib/odoo
      - ./odoo/local-src:/odoo/local-src
    restart: unless-stopped
  db:
    image: postgres:16
    container_name: itipart-postgres
    environment:
      - POSTGRES_DB=postgres
      - POSTGRES_USER=odoo
      - POSTGRES_PASSWORD=admin
    volumes:
      - postgres-data:/var/lib/postgresql/data
    restart: unless-stopped
volumes:
  odoo-data:
  postgres-data:
EOF

# Create .env file
cat > .env << 'EOF'
HOST=localhost
USER=admin
PASSWORD=admin
PGDATABASE=postgres
PGHOST=db
PGPORT=5432
PGUSER=odoo
EOF

# Create requirements.txt
cat > odoo/requirements.txt << 'EOF'
psycopg2-binary
python-dateutil
pytz
reportlab
lxml
pillow
pyopenssl
cryptography
pycparser
EOF

echo "ITIPART Docky setup complete"
echo "Next steps:"
echo "1. pipx install docky"
echo "2. docky build"
echo "3. docky run"
echo "4. Access at http://localhost:8069"
```

## Usage Notes

- Scripts are designed for **diagnostic purposes**
- Always **review scripts** before running in production
- Test in **non-production environments** first
- Document **changes and results** for future reference

## Reference Files

- `ssh-permission-fixes.md` - Common fixes and workarounds
- `ssh-diagnostics.md` - Diagnostic commands and scripts
- `ssh-config-examples.md` - Configuration file examples

## Triggers

This reference is consulted when:
- SSH diagnostics needed
- Permission issues encountered
- Troubleshooting SSH connections
- Setting up custom SSH configurations