---
name: akretion-docker-infra
description: Use Copier, AK, and Docky for Odoo Docker projects.
version: 1.0.0
---

# Akretion Docker Compose Infrastructure Guide

## Overview

This skill provides comprehensive guidance for working with Akretion's Docker Compose-based Odoo infrastructure using **Copier**, **AK**, and **Docky** tools. This approach provides a standardized, reproducible way to create and manage Odoo projects.

## Core Components

### 1. Copier
**Template-based project generator**
- Creates project structure from templates
- Handles Jinja2 templating
- Manages project configuration

### 2. AK (Akretion Kit)
**Git aggregator wrapper**
- Manages Odoo source code and modules
- Uses git-aggregator under the hood
- Handles repository specifications

### 3. Docky
**Docker Compose manager**
- Simplifies Docker Compose workflows
- Handles environment variables
- Manages service lifecycle

## Getting Started

### Installation

```bash
# Install required tools
pipx install copier
pipx install docky
pipx install git+https://github.com/akretion/ak.git@master

# Or with pip in virtual environment
python3 -m venv akretion-venv
source akretion-venv/bin/activate
pip install copier docky git+https://github.com/akretion/ak.git@master
```

### Create a New Odoo Project

```bash
# 1. Create empty project directory
mkdir my-odoo-project
cd my-odoo-project

# 2. Initialize project from template
copier copy https://github.com/akretion/docky-odoo-template-shared .

# 3. Add personal configuration
copier copy https://github.com/akretion/docky-odoo-template-personal .

# 4. Download Odoo source and modules
cd odoo
ak clone
ak build

# 5. Start the project
cd ..
docky run
```

## Project Structure

```
my-odoo-project/
├── .copier-answers.yml          # Copier configuration answers
├── .env                         # Environment variables
├── docker-compose.yml           # Main Docker Compose file
├── dev.docker-compose.yml      # Development overrides
├── prod.docker-compose.yml     # Production overrides
├── odoo/
│   ├── Dockerfile              # Odoo container definition
│   ├── spec.yaml               # Module specifications
│   ├── requirements.txt        # Python requirements
│   ├── local-src/              # Custom modules
│   └── setup.py                # Setup script
└── bin/                        # Utility scripts
```

## Key Files Explained

### spec.yaml

The `spec.yaml` file defines which Odoo repositories and modules to include:

```yaml
odoo:
    src: https://github.com/odoo/odoo {{ odoo_version }}

server-tools:
    modules:
        - sentry
        - bus_alt_connection
    src: https://github.com/oca/server-tools {{ odoo_version }}

web:
    modules:
        - web_environment_ribbon
    src: https://github.com/oca/web {{ odoo_version }}
```

### docker-compose.yml

Main Docker Compose configuration with Odoo service:

```yaml
services:
  odoo:
    environment:
      ENCRYPTION_KEY_DEV:
      KWKHTMLTOPDF_SERVER_URL: http://kwkhtmltopdf:8080
      ODOO_QUEUE_JOB_CHANNELS: root:6,root.pattern.import:1
      LIMIT_MEMORY_SOFT: 629145600
      LIMIT_MEMORY_HARD: 2147483648
    hostname: ${ENV}-${COMPOSE_PROJECT_NAME}
    labels:
      docky.main.service: true
      docky.user: odoo
```

## Common Commands

### Project Setup

```bash
# Initialize new project
copier copy https://github.com/akretion/docky-odoo-template-shared my-project

# Update existing project
copier update

# Show available templates
copier info https://github.com/akretion/docky-odoo-template-shared
```

### Module Management

```bash
# Clone repositories defined in spec.yaml
ak clone

# Build/aggregate modules
ak build

# Update modules
ak update

# Show status
ak status
```

### Docker Management

```bash
# Start services
docky run

# Build/rebuild containers
docky build

# Stop services
docky stop

# View logs
docky logs

# Execute command in container
docky exec odoo /bin/bash
```

## Advanced Usage

### Customizing Templates

Create a custom template by forking the base template and modifying:
- `copier.yml` - Configuration questions
- Template files with `.jinja` extension
- Default values and structure

### Multi-Environment Setup

```bash
# Development environment
cp .env.example .env.dev
ENV=dev docky run

# Production environment
cp .env.example .env.prod
ENV=prod docky run
```

### Adding Custom Modules

```bash
# Add module to spec.yaml
custom-modules:
    modules:
        - my_custom_module
    src: https://github.com/myorg/my-custom-modules {{ odoo_version }}

# Then rebuild
ak update
ak build
```

## Troubleshooting

### Common Issues

**Issue: `ak clone` fails**
- Check internet connectivity
- Verify GitHub access tokens
- Ensure spec.yaml has valid repository URLs

**Issue: `docky run` fails**
- Check Docker is running
- Verify port conflicts
- Review environment variables in .env

**Issue: Module not found**
- Run `ak status` to check repository status
- Ensure module is listed in spec.yaml
- Check Odoo version compatibility

### Debugging Commands

```bash
# Check AK status
ak status

# Verify Docker Compose configuration
docky config

# Test template rendering
copier copy --dry-run https://github.com/akretion/docky-odoo-template-shared .
```

## Best Practices

### Project Organization
- Keep custom modules in `odoo/local-src/`
- Use separate branches for different Odoo versions
- Document customizations in README.md

### Version Control
- Commit `.copier-answers.yml` to track configuration
- Include `spec.yaml` in version control
- Use `.env.example` for environment templates

### Performance Optimization
- Use `LIMIT_MEMORY_SOFT` appropriate for module count
- Adjust `ODOO_QUEUE_JOB_CHANNELS` based on workload
- Monitor resource usage with `docky stats`

## Migration Guide

### From Traditional Setup to Docky

```bash
# 1. Create new docky project
copier copy https://github.com/akretion/docky-odoo-template-shared new-project

# 2. Copy custom modules to new-project/odoo/local-src/

# 3. Update spec.yaml with your repositories

# 4. Test with docky run

# 5. Gradually migrate configuration
```

### Upgrading Odoo Versions

```bash
# 1. Update odoo_version in .copier-answers.yml

# 2. Update spec.yaml with new version

# 3. Run copier update

# 4. Rebuild modules
ak update
ak build

# 5. Test thoroughly
```

## Resources

### Official Documentation
- [docky-odoo-template-shared](https://github.com/akretion/docky-odoo-template-shared)
- [docky](https://github.com/akretion/docky)
- [ak](https://github.com/akretion/ak)
- [copier](https://github.com/copier-org/copier)

### Related Templates
- [docky-odoo-template-personal](https://github.com/akretion/docky-odoo-template-personal)
- [oca-addons-repo-template](https://github.com/OCA/oca-addons-repo-template)

### Tools Reference
- [git-aggregator](https://github.com/acsone/git-aggregator)
- [Docker Compose](https://docs.docker.com/compose/)

## Usage Examples

### Create Development Project

```bash
# Create project for Odoo 18.0
mkdir my-project && cd my-project
copier copy -d project_name=my-project -d branch_name=18.0 \
  https://github.com/akretion/docky-odoo-template-shared .

# Add personal config
copier copy https://github.com/akretion/docky-odoo-template-personal .

# Setup and run
cd odoo && ak clone && ak build
cd .. && docky run
```

### Add Custom Module

```bash
# Edit spec.yaml
nano odoo/spec.yaml

# Add your module
my-custom-modules:
    modules:
        - my_awesome_module
    src: https://github.com/myorg/my-modules 18.0

# Update and rebuild
ak update
ak build

# Restart services
docky build
docky run
```

### Update Existing Project

```bash
# Pull latest template changes
copier update

# Update modules
cd odoo
ak update
ak build

# Rebuild containers
cd ..
docky build
docky run
```

## Triggers

This skill is automatically invoked when you ask about:
- Akretion Docker infrastructure
- Docky Odoo setup
- Copier templates for Odoo
- AK tool usage
- Odoo Docker Compose setup
- Akretion project templates
- Odoo development environment setup
- git-aggregator for Odoo modules