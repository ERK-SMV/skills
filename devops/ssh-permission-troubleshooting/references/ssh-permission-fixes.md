# SSH Permission Fixes and Workarounds

## Custom SSH Agent Socket Setup

### Problem
SSH agent cannot bind to `/tmp` due to permission restrictions.

### Solution
```bash
# Create custom socket directory
mkdir -p ~/.ssh/sockets
chmod 700 ~/.ssh/sockets

# Set custom socket path
export SSH_AUTH_SOCK=~/.ssh/sockets/ssh_auth_sock

# Start SSH agent with custom socket
ssh-agent -a $SSH_AUTH_SOCK

# Add SSH keys
ssh-add ~/.ssh/id_rsa_github
ssh-add ~/.ssh/id_ed25519_ak-gitlab-smv

# Verify
ssh-add -l
```

### Verification
```bash
# Test GitHub connection
ssh -T git@github.com

# Test GitLab connection
ssh -T git@gitlab.com
```

## Copier Template Workarounds

### Problem
Copier fails when trying to clone templates to `/tmp`.

### Solution 1: Use HTTPS with Tokens
```bash
# For GitHub
copier copy https://oauth2:YOUR_GITHUB_TOKEN@github.com/akretion/docky-odoo-template-shared .

# For GitLab
copier copy https://oauth2:YOUR_GITLAB_TOKEN@gitlab.com/akretion/docky-odoo-template-shared .
```

### Solution 2: Manual Clone
```bash
# Clone manually
git clone https://github.com/akretion/docky-odoo-template-shared.git ~/docky-template

# Use copier with local path
copier copy ~/docky-template .
```

### Solution 3: Change TMPDIR
```bash
# Set alternative temp directory
export TMPDIR=$HOME/tmp
mkdir -p $TMPDIR

# Try copier again
copier copy https://github.com/akretion/docky-odoo-template-shared .
```

## ITIPART-Specific Docky Setup

### Manual Docky Structure
```bash
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
```

### Setup Commands
```bash
# Install Docky
pipx install docky

# Build images
docky build

# Start services
docky run

# Access at http://localhost:8069
```

## Diagnostic Commands

### SSH Agent Diagnostics
```bash
# Check if SSH agent is running
ps aux | grep ssh-agent

# Check SSH_AUTH_SOCK
echo $SSH_AUTH_SOCK

# Check socket file
ls -la $SSH_AUTH_SOCK 2>/dev/null || echo "Socket not found"

# List added keys
ssh-add -l
```

### Permission Diagnostics
```bash
# Check home directory
ls -ld ~

# Check .ssh directory
ls -ld ~/.ssh

# Check key permissions
ls -la ~/.ssh/id_*

# Check /tmp permissions
ls -ld /tmp
```

### Git Diagnostics
```bash
# Test SSH git clone
GIT_SSH_COMMAND='ssh -v' git clone git@github.com:user/repo.git

# Test HTTPS git clone
git clone https://github.com/user/repo.git

# Test with specific key
ssh -i ~/.ssh/id_rsa -T git@github.com
```

## Session-Specific Fixes

### Session: 2026-08-04 - ITIPART Docky Setup

**Problem:** User encountered SSH agent permission issues when trying to set up Docky for ITIPART project.

**Root Cause:**
- `/tmp` directory had restrictive permissions
- SSH agent couldn't create socket files
- Copier template cloning failed due to `/tmp` issues

**Solution Applied:**
1. Created custom SSH socket directory: `~/.ssh/sockets/`
2. Used custom socket path: `~/.ssh/sockets/ssh_auth_sock`
3. Added GitHub SSH key successfully
4. Created manual Docky setup for ITIPART project
5. Provided comprehensive troubleshooting guide

**Workarounds Provided:**
- Custom SSH agent socket location
- HTTPS with tokens for copier
- Manual Docky structure creation
- Complete ITIPART-specific configuration

**Outcome:** User able to proceed with ITIPART Docky setup despite SSH limitations.