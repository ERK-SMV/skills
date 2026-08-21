---
name: docker-docky-management
description: Docker/Docky Odoo dev workflow using Akretion's toolchain.
version: 1.0.0
author: Akretion / Odoo Open-Source Developer
tags: [docker, docky, odoo, containerization, devops, akretion, copier, ak, pipx]
license: MIT
platforms: [linux, macos]
metadata:
  hermes:
    tags: [docker, docky, containerization, odoo, devops, akretion, development]
    related_skills: [odoo-opensource-developper, plan, test-driven-development]
    supporting_files_dir: "./docker-docky-supporting-files"
---

# Docker & Docky Management with AKRETION Tools

This skill provides comprehensive guidance for **Docker and Docky-based Odoo development** using **Akretion's toolchain**: DOCKY, PIPX, COPIER, and AK (git-aggregator).

## Core Tools Overview

### 1. DOCKY (Akretion's Docker Image Structuring Convention)

**Description:** Docky is Akretion's convention for structuring Docker images for Odoo projects. It provides a standardized way to build, manage, and deploy Odoo instances in containers.

**Key Features:**
- Multi-stage Docker builds (base → thisproject → test/prod/dev)
- Standardized Dockerfile structure
- Integration with docker-compose
- Environment variable management
- Support for development, test, and production modes

**GitHub:** https://github.com/akretion/docky

### 2. PIPX (Python Package Installer for CLI Tools)

**Description:** pipx is a tool for installing and managing Python packages in isolated environments, specifically designed for CLI applications.

**Why Use pipx:**
- Installs Python packages in isolated environments
- Ensures CLI tools don't conflict with each other
- Keeps your system Python clean
- Automatic dependency management

**GitHub:** https://github.com/pypa/pipx

### 3. COPIER (Template Rendering Tool)

**Description:** Copier is a library and CLI tool for rendering project templates. It's the spiritual successor to Cookiecutter, with better Jinja2 support and more flexibility.

**Key Features:**
- Jinja2 templating with full Python support
- YAML-based configuration (copier.yml)
- Support for update workflows
- Subdirectory template support
- Preservation of user modifications

**GitHub:** https://github.com/copier-org/copier

**Configuration:** See [`copier.yml`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/app/second-brain/odoo-opensource-developper/docky-odoo-template-shared/copier.yml) in docky-odoo-template-shared

### 4. AK (git-aggregator)

**Description:** AK is Akretion's wrapper around git-aggregator, a tool for cloning and merging multiple Git repositories based on a specification file.

**Key Features:**
- Multi-repository management
- Specification-based (spec.yaml)
- Automatic dependency resolution
- Support for different branch strategies
- Integration with Odoo module ecosystem

**GitHub:** https://github.com/akretion/ak

**Underlying Tool:** https://github.com/acsone/git-aggregator

---

## Installation

### Prerequisites

- Python 3.8+
- pip (Python package manager)
- Docker
- Docker Compose
- Git

### Install AKRETION Tools with pipx

```bash
# Install pipx first (if not already installed)
python3 -m pip install --user pipx
python3 -m pipx ensurepath

# Restart shell or source your profile
# Then install the AKRETION toolchain

pipx install docky
pipx install copier
pipx install git+https://github.com/akretion/ak.git@master

# Verify installations
pipx list
```

**Expected Output:**
```
docky         8.0.0+    /home/user/.local/pipx/venvs/docky
copier        9.0.0+    /home/user/.local/pipx/venvs/copier
ak            1.0.0+    /home/user/.local/pipx/venvs/ak
```

---

## Quick Start

### 1. Create a New Odoo Project

```bash
# Create an empty directory for your project
mkdir my-odoo-project
cd my-odoo-project

# Use copier to initialize from docky-odoo-template-shared
copier copy https://github.com/akretion/docky-odoo-template-shared .

# You'll be prompted for:
# - project_name: Your project name
# - branch_name: Odoo version (19.0, 18.0, 17.0, etc.)
# - org_name: Organization name (default: Akretion)
```

### 2. Create Personal Configuration

```bash
# Use copier again with docky-odoo-template-personal
copier copy https://github.com/akretion/docky-odoo-template-personal .
```

### 3. Download Odoo Source and Modules

```bash
cd odoo

# Clone repositories based on spec.yaml
ak clone

# Build Docker images
ak build
```

### 4. Run the Project

```bash
cd ..

# Run in development mode
docky run

# Or run in test mode
docky run -c dev

# Or run in production mode
docky run -c prod
```

### 5. Build Docker Images

```bash
# Build the base image
docky build

# Or build with a specific target
docker build --target test --tag my-odoo:test .

# Or build production image
docker build --target prod --tag my-odoo:prod .
```

---

## Command Reference

### DOCKY Commands

| Command | Description | Example |
|---------|-------------|---------|
| `docky run` | Start containers | `docky run` |
| `docky run -c dev` | Start in dev mode | `docky run -c dev` |
| `docky run -c prod` | Start in production mode | `docky run -c prod` |
| `docky build` | Build Docker images | `docky build` |
| `docky exec` | Execute command in container | `docky exec -c odoo -u odoo -- psql` |
| `docky logs` | View container logs | `docky logs -c odoo` |
| `docky down` | Stop containers | `docky down` |
| `docky ps` | List running containers | `docky ps` |
| `docky pull` | Pull latest images | `docky pull` |
| `docky push` | Push images to registry | `docky push` |

**DOCKY Environment Variables:**
- `DOCKY_COMPOSE_FILE`: Custom docker-compose file (default: docker-compose.yml)
- `DOCKY_ENV_FILE`: Custom environment file (default: .env)
- `DOCKY_PROJECT_NAME`: Project name for containers

### COPIER Commands

| Command | Description | Example |
|---------|-------------|---------|
| `copier copy` | Copy template to destination | `copier copy <template_url> <dest>` |
| `copier update` | Update existing project from template | `copier update -A` |
| `copier diff` | Show changes from template | `copier diff` |

**COPIER Flags:**
- `-A, --answers`: Use answers from previous run
- `--trust`: Trust the template without confirmation
- `-f, --force`: Force overwrite
- `--data`: Override template variables
- `--skip`: Skip files that already exist

### AK (git-aggregator) Commands

| Command | Description | Example |
|---------|-------------|---------|
| `ak clone` | Clone repositories from spec.yaml | `ak clone` |
| `ak build` | Build/merge repositories | `ak build` |
| `ak update` | Update repositories | `ak update` |
| `ak status` | Show repository status | `ak status` |
| `ak add` | Add a new repository | `ak add <repo_url> <path>` |
| `ak remove` | Remove a repository | `ak remove <path>` |

**AK Configuration:**
- Main configuration file: `odoo/spec.yaml`
- Defines repositories, branches, and merge strategy

### PIPX Commands

| Command | Description | Example |
|---------|-------------|---------|
| `pipx install` | Install a package | `pipx install docky` |
| `pipx uninstall` | Uninstall a package | `pipx uninstall docky` |
| `pipx list` | List installed packages | `pipx list` |
| `pipx run` | Run a package without installing | `pipx run docky --version` |
| `pipx upgrade` | Upgrade all packages | `pipx upgrade-all` |
| `pipx inject` | Add packages to environment | `pipx inject docky Dependency` |

---

## Project Structure

After using copier with docky-odoo-template-shared, your project will have this structure:

```
my-odoo-project/
├── .copier-answers.yml          # Copier answers file
├── .env                         # Environment variables (from template-personal)
├── .env-ci                      # CI environment variables
├── .env-dev                     # Development environment variables
├── .gitignore
├── ci.docker-compose.yml        # CI-specific compose file
├── ci.secrets.docker-compose.yml
├── dev.docker-compose.yml       # Development compose file
├── docker-compose.yml           # Main compose file
├── prod.docker-compose.yml      # Production compose file
├── prod.secrets.docker-compose.yml
├── kwkhtmltopdf-traefik.docker-compose.yml
├── odoo/
│   ├── Dockerfile               # Multi-stage Docker build
│   ├── README.md
│   ├── local-src/               # Custom modules
│   ├── patches/                 # Module patches
│   ├── requirements.txt         # Python dependencies
│   ├── setup.py
│   └── spec.yaml               # AK git-aggregator spec
└── backup/                      # Backup scripts
```

---

## Dockerfile Structure (Multi-Stage Build)

The Docky convention uses a multi-stage Dockerfile:

```dockerfile
# Stage 1: base
FROM ghcr.io/akretion/odoo-docker:18.0-light-latest as base

# Stage 2: thisproject
FROM base as thisproject
USER root

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    python3-dev \
    && apt-get clean

# Copy project files
COPY odoo/requirements.txt /requirements.txt
RUN pip install -r /requirements.txt

# Stage 3: test
FROM thisproject as test
USER odoo
COPY --chown=odoo:odoo odoo/ /odoo
RUN /odoo/odoo-bin -i base -d test --without-demo=ALL --stop-after-init

# Stage 4: prod
FROM thisproject as prod
USER odoo
COPY --chown=odoo:odoo odoo/ /odoo
RUN /odoo/odoo-bin -i base -d prod --without-demo=ALL --stop-after-init

# Default command
CMD ["/odoo/odoo-bin"]
```

**Build Targets:**
- `base`: Minimal Odoo image
- `thisproject`: Base + project dependencies
- `test`: Test environment with demo data
- `prod`: Production-ready image

---

## docker-compose.yml Configuration

The main docker-compose.yml typically includes:

```yaml
version: '3.8'

services:
  odoo:
    build:
      context: .
      dockerfile: odoo/Dockerfile
      target: thisproject  # or test/prod
    image: my-odoo-project:latest
    container_name: odoo
    environment:
      - HOST=${HOST}
      - USER=${USER}
      - PASSWORD=${PASSWORD}
      - PGDATABASE=${PGDATABASE}
      - PGHOST=${PGHOST}
      - PGPORT=${PGPORT}
      - PGUSER=${PGUSER}
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
    container_name: postgres
    environment:
      - POSTGRES_DB=${PGDATABASE}
      - POSTGRES_USER=${PGUSER}
      - POSTGRES_PASSWORD=${PASSWORD}
    volumes:
      - postgres-data:/var/lib/postgresql/data
    restart: unless-stopped

volumes:
  odoo-data:
  postgres-data:
```

---

## spec.yaml Configuration

The `odoo/spec.yaml` file defines repositories for AK (git-aggregator):

```yaml
repos:
  - repo: https://github.com/odoo/odoo.git
    branch: 18.0
    target: odoo

  - repo: https://github.com/OCA/OCB.git
    branch: 18.0
    target: odoo/oca

  - repo: https://github.com/OCA/account-invoicing.git
    branch: 18.0
    target: odoo/oca/account-invoicing

  - repo: https://github.com/Akretion/ak-invoicing.git
    branch: 18.0
    target: odoo/local-src/ak-invoicing

merge_strategy:
  - strategy: merge
    pattern: odoo/addons/*
  
  - strategy: replace
    pattern: odoo/addons/base/**

patches:
  - path: odoo/patches
    apply: true
```

**AK Commands with spec.yaml:**
```bash
# Clone all repositories defined in spec.yaml
ak clone

# Clone with specific target
ak clone odoo/spec.yaml

# Build/merge all repositories
ak build

# Update repositories
ak update

# Add a new repository
ak add https://github.com/YourOrg/your-repo.git odoo/local-src/your-repo

# Check status
ak status
```

---

## Environment Variables

### Common .env Variables

```bash
# Odoo Database
PGDATABASE=odoo
PGHOST=db
PGPORT=5432
PGUSER=odoo
PASSWORD=odoo

# Odoo
HOST=localhost
USER=admin
PASSWORD=admin

# Docker
DOCKER_REGISTRY=registry.gitlab.com
DOCKER_IMAGE_NAME=my-odoo-project
DOCKER_IMAGE_TAG=latest

# Project
PROJECT_NAME=my-odoo-project
ODOO_VERSION=18.0
```

### Development vs Production Variables

**Development (.env-dev):**
```bash
ODOO_DEBUG=1
ODOO_AUTORELOAD=1
```

**Production (.env-prod):**
```bash
ODOO_DEBUG=0
ODOO_AUTORELOAD=0
WORKERS=4
MAXCRON=4
```

---

## Workflow Examples

### Example 1: Starting a New Odoo 18 Project

```bash
# 1. Install tools
pipx install docky
pipx install copier
pipx install git+https://github.com/akretion/ak.git@master

# 2. Create project directory
mkdir odoo18-myproject
cd odoo18-myproject

# 3. Initialize with shared template
copier copy https://github.com/akretion/docky-odoo-template-shared .
# Answer: project_name=odoo18-myproject, branch_name=18.0

# 4. Add personal configuration
copier copy https://github.com/akretion/docky-odoo-template-personal .

# 5. Download Odoo and modules
cd odoo
ak clone
ak build
cd ..

# 6. Start development environment
docky run -c dev

# 7. Access Odoo at http://localhost:8069
```

### Example 2: Updating an Existing Project

```bash
# 1. Pull latest changes
cd my-odoo-project
git pull

# 2. Update from template (if needed)
copier update -A

# 3. Update repositories
cd odoo
ak update
ak build
cd ..

# 4. Rebuild Docker images
docky build

# 5. Restart containers
docky down
docky run -c dev
```

### Example 3: Production Deployment

```bash
# 1. Build production image
cd my-odoo-project
docker build --target prod --tag registry.example.com/my-odoo:1.0.0 .

# 2. Push to registry
docker push registry.example.com/my-odoo:1.0.0

# 3. Deploy with docker-compose
docky run -c prod
```

### Example 4: Adding a Custom Module

```bash
# 1. Add module to spec.yaml
cd my-odoo-project/odoo
# Edit spec.yaml to add your module

# 2. Rebuild
ak clone
ak build

# 3. Restart Odoo
docky restart odoo
```

### Example 5: Database Operations

```bash
# Create database
docky exec -c odoo -u odoo -- odoo-bin -i mymodule -d mydb --without-demo=ALL

# Update module
docky exec -c odoo -u odoo -- odoo-bin -u mymodule -d mydb

# Backup database
docky exec -c db -- pg_dump -U odoo -d mydb > mydb_backup.sql

# Restore database
cat mydb_backup.sql | docky exec -i -c db -- psql -U odoo -d mydb
```

---

## Traefik Reverse Proxy Setup

### Overview
Traefik is a modern reverse proxy and load balancer that integrates seamlessly with Docker. For ITIPART development, you can use Traefik to route requests to your Odoo instance.

### Basic Traefik Commands

```bash
# Create Traefik network
docker network create traefik_network

# Start Traefik service
docker-compose -f kwkhtmltopdf-traefik.docker-compose.yml up -d

# View Traefik logs
docker-compose -f kwkhtmltopdf-traefik.docker-compose.yml logs -f

# Stop Traefik service
docker-compose -f kwkhtmltopdf-traefik.docker-compose.yml down

# Check Traefik container status
docker ps | grep traefik
```

### Development Traefik Configuration

Here's a working Traefik configuration for development:

```yaml
# kwkhtmltopdf-traefik.docker-compose.yml
version: '3.8'

services:
  traefik:
    image: traefik:v2.10
    container_name: traefik
    command:
      - "--api.insecure=true"  # For development only
      - "--providers.docker=true"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"  # Dashboard
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - traefik_network

networks:
  traefik_network:
    driver: bridge
```

### Configure Odoo for Traefik

Add these labels to your Odoo service in `docker-compose.yml`:

```yaml
services:
  odoo:
    # ... existing configuration ...
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.odoo.rule=Host(`odoo.itipart.local`)"
      - "traefik.http.routers.odoo.entrypoints=web"
      - "traefik.http.services.odoo.loadbalancer.server.port=8069"
    networks:
      - default
      - traefik_network

networks:
  traefik_network:
    external: true
```

### Start Everything Together

```bash
# Create the Traefik network first
docker network create traefik_network

# Start Traefik
docker-compose -f kwkhtmltopdf-traefik.docker-compose.yml up -d

# Start your Odoo services
docky run -c dev

# Verify Traefik is routing
curl -H "Host: odoo.itipart.local" http://localhost
```

### Traefik Dashboard Access

```bash
# Access the Traefik dashboard
# URL: http://localhost:8080

# Secure dashboard (optional):
labels:
  - "traefik.http.routers.dashboard.rule=Host(`traefik.itipart.local`)"
  - "traefik.http.routers.dashboard.service=api@internal"
  - "traefik.http.routers.dashboard.middlewares=auth"
  - "traefik.http.middlewares.auth.basicauth.users=admin:$$apr1$$hashedpassword"
```

### ITIPART-Specific Traefik Setup

For your ITIPART project in development:

1. **Configure a domain** for your ITIPART Odoo instance
2. **Set up HTTPS** with Let's Encrypt (for production)
3. **Configure routing** for your custom modules

```yaml
# Add to your kwkhtmltopdf-traefik.docker-compose.yml
services:
  traefik:
    command:
      - "--certificatesresolvers.myresolver.acme.tlschallenge=true"
      - "--certificatesresolvers.myresolver.acme.email=your@email.com"
      - "--certificatesresolvers.myresolver.acme.storage=/letsencrypt/acme.json"
    volumes:
      - ./letsencrypt:/letsencrypt

# In your Odoo service labels:
labels:
  - "traefik.http.routers.odoo.tls=true"
  - "traefik.http.routers.odoo.tls.certresolver=myresolver"
  - "traefik.http.routers.odoo.rule=Host(`odoo.itipart.com`)"
```

### Traefik Debugging Commands

```bash
# Check Traefik is running
docker ps | grep traefik

# Check Traefik logs
docker logs traefik

# Test Traefik API
curl http://localhost:8080/api/http/routers

# Check Odoo container labels
docker inspect <odoo_container_name> | jq '.[0].Config.Labels'

# Test direct Odoo access
curl http://localhost:8069
```

### Common Traefik Issues and Solutions

| Issue | Solution |
|-------|----------|
| Traefik not starting | Check logs: `docker logs traefik` |
| 404 Not Found | Verify host header: `curl -H "Host: odoo.itipart.local" http://localhost` |
| Port conflicts | Check ports: `ss -tulnp | grep ':80\|:443\|:8080'` |
| No routers found | Check labels: `docker inspect <container> | grep -A 10 Labels` |
| SSL errors | Verify cert resolver: `docker logs traefik | grep acme` |

### Simplified Development Approach

If you're still having issues, try this simplified approach:

```bash
# Create a minimal traefik setup
cat > traefik-dev.yml << 'EOF'
version: '3.8'

services:
  traefik:
    image: traefik:v2.10
    command:
      - "--api.insecure=true"
      - "--providers.docker"
      - "--entrypoints.web.address=:80"
    ports:
      - "80:80"
      - "8080:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    networks:
      - default

networks:
  default:
    driver: bridge
EOF

# Start it
docker-compose -f traefik-dev.yml up -d

# Update your Odoo service labels
# Add to your odoo service in docker-compose.yml:
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.myodoo.rule=Host(`myodoo.local`)"
  - "traefik.http.routers.myodoo.entrypoints=web"
  - "traefik.http.services.myodoo.loadbalancer.server.port=8069"

# Restart your services
docky down
docky run -c dev
```

### Add to hosts file

```bash
echo "127.0.0.1 odoo.itipart.local" | sudo tee -a /etc/hosts
echo "127.0.0.1 traefik.itipart.local" | sudo tee -a /etc/hosts
```

Now you can access:
- Odoo: http://odoo.itipart.local
- Traefik dashboard: http://localhost:8080

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| `docky: command not found` | pipx not in PATH | Add pipx to PATH or source ~/.bashrc |
| `copier: command not found` | pipx not in PATH | Add pipx to PATH or source ~/.bashrc |
| `ak: command not found` | pipx not in PATH | Add pipx to PATH or source ~/.bashrc |
| Permission denied on docker | User not in docker group | `sudo usermod -aG docker $USER` then logout/login |
| Port 8069 already in use | Another Odoo instance | `docky down` or change port in docker-compose.yml |
| Database connection failed | Wrong credentials | Check .env file and database service |
| Modules not loaded | Missing in spec.yaml | Add repository to spec.yaml and run `ak clone` |
| Build fails | Missing dependencies | Check Dockerfile and requirements.txt |

### Debug Commands

```bash
# Check running containers
docker ps

# View container logs
docker logs <container_name>

# Exec into container
docker exec -it <container_name> bash

# Check disk usage
docker system df

# Clean unused objects
docker system prune

# Check port usage
ss -tulnp | grep 8069

# Check environment variables
docky exec -c odoo -- env
```

---

## Best Practices

### 1. Use Multi-Stage Builds
Always use multi-stage builds to keep production images small:
```dockerfile
FROM base as thisproject
# Install dev dependencies

FROM thisproject as prod
# Only copy what's needed for production
```

### 2. Pin Versions
Pin all dependency versions in:
- requirements.txt
- spec.yaml (repo branches)
- docker-compose.yml (image tags)

### 3. Use .dockerignore
Create a `.dockerignore` file to exclude unnecessary files:
```
.git
.gitignore
__pycache__
*.pyc
*.swp
.DS_Store
.env
.env.*
docker-compose*.yml
```

### 4. Environment Separation
Maintain separate environment files:
- `.env` - Default/local development
- `.env-dev` - Development-specific
- `.env-prod` - Production
- `.env-ci` - CI/CD pipeline

### 5. Regular Updates
```bash
# Update AKRETION tools
pipx upgrade-all

# Update templates
copier update -A

# Update Odoo and modules
cd odoo && ak update && ak build
```

### 6. Clean Builds
```bash
# Clean and rebuild
rm -rf odoo/local-src/*
docker system prune -a
docky build --no-cache
```

---

## AKRETION Commands Cheat Sheet

### DOCKY
```bash
# Start all services
docky run

# Start with specific compose file
docky run -c dev.docker-compose.yml

# Build images
docky build

# View logs
docky logs -c odoo

# Execute command
docky exec -c odoo -u odoo -- odoo-bin --version

# Stop all services
docky down

# List services
docky ps
```

### COPIER
```bash
# Copy template
copier copy <template_url> <destination>

# Update from template
copier update

# Force update
copier update -f

# Show diff
copier diff

# Copy with data
copier copy --data key=value <template> <dest>
```

### AK
```bash
# Clone all repos from spec.yaml
ak clone

# Clone specific spec file
ak clone path/to/spec.yaml

# Build/merge repos
ak build

# Update repos
ak update

# Add repo
ak add <url> <target_path>

# Remove repo
ak remove <target_path>

# Show status
ak status

# Show changes
ak changes
```

### PIPX
```bash
# Install package
pipx install <package>

# Install from git
pipx install git+https://github.com/user/repo.git

# List packages
pipx list

# Run without install
pipx run <package> --version

# Upgrade all
pipx upgrade-all

# Uninstall
pipx uninstall <package>
```

---

## Supporting Files Directory

The supporting files for this skill are located in:
```
./docker-docky-supporting-files/
```

This directory contains:
- Sample Dockerfiles
- docker-compose.yml templates
- spec.yaml examples
- .env files
- Copier configuration examples

---

## Related Resources

- **Docky Repository:** https://github.com/akretion/docky
- **Copier Repository:** https://github.com/copier-org/copier
- **AK Repository:** https://github.com/akretion/ak
- **git-aggregator:** https://github.com/acsone/git-aggregator
- **Odoo Docker Images:** https://github.com/akretion/odoo-docker
- **pipx Repository:** https://github.com/pypa/pipx

- **Template Repositories:**
  - https://github.com/akretion/docky-odoo-template-shared
  - https://github.com/akretion/docky-odoo-template-personal
  - https://github.com/OCA/oca-addons-repo-template

- **Akretion Website:** https://akretion.com

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-07-25 | Initial release with AKRETION tools integration |

---

## Usage Triggers

This skill is automatically invoked when you ask about:
- Docker and Docky management
- Odoo containerization with Docky
- AKRETION tools (docky, copier, ak, pipx)
- Odoo project setup with templates
- Multi-repository management with git-aggregator
- Docker multi-stage builds for Odoo
- Odoo development environment setup

---

**Note:** All commands and examples in this skill are based on Akretion's conventions and best practices for Odoo development. For the most up-to-date information, refer to the official documentation of each tool.
