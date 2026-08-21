---
name: ssh-permission-troubleshooting
description: Fix SSH permission issues in restricted environments.
version: 1.0.0
---

# SSH Permission Troubleshooting

## Overview

This skill provides comprehensive guidance for troubleshooting and fixing SSH permission issues, particularly in restricted environments where `/tmp` directory permissions prevent SSH agent from working.

## Common SSH Permission Issues

### 1. SSH Agent Cannot Bind to /tmp
**Error:** `unix_listener: cannot bind to path /tmp/ssh-XXXXXX/agent.XXXX: Permission denied`

**Causes:**
- Restrictive `/tmp` directory permissions
- User context without write access to `/tmp`
- Containerized environments with limited permissions

### 2. Copier Template Cloning Failures
**Error:** `fatal: Invalid path '/tmp/copier._vcs.clone.XXXXXX/.git': Permission denied`

**Causes:**
- Copier trying to clone templates to `/tmp`
- Git unable to create `.git` directories in `/tmp`
- Permission issues in temporary directories

### 3. SSH Key Permission Issues
**Error:** `Permissions 0644 for 'id_rsa' are too open.`

**Causes:**
- SSH keys with incorrect file permissions
- Directory permissions too permissive
- Group or world-readable SSH keys

## Solutions

### Solution 1: Custom SSH Agent Socket Location

```bash
# Create a personal socket directory
mkdir -p ~/.ssh/sockets
chmod 700 ~/.ssh/sockets

# Set custom socket path
export SSH_AUTH_SOCK=~/.ssh/sockets/ssh_auth_sock

# Start SSH agent with custom socket
ssh-agent -a $SSH_AUTH_SOCK

# Add SSH keys
ssh-add ~/.ssh/id_rsa
ssh-add ~/.ssh/id_ed25519

# Verify keys are added
ssh-add -l
```

**Explanation:**
- Creates a socket directory in your home folder where you have write permissions
- Uses a custom socket path instead of the default `/tmp` location
- Allows SSH agent to work in restricted environments

### Solution 2: Fix /tmp Permissions (Requires sudo)

```bash
# Check current /tmp permissions
ls -ld /tmp

# Fix permissions (requires sudo)
sudo chmod 1777 /tmp

# Verify fix
ls -ld /tmp

# Try SSH agent again
eval "$(ssh-agent -s)"
```

**Note:** This requires sudo privileges and may not be available in all environments.

### Solution 3: Use SSH Without Agent

```bash
# Test SSH connection with explicit key
ssh -i ~/.ssh/id_rsa git@github.com

# For git operations
GIT_SSH_COMMAND='ssh -i ~/.ssh/id_rsa' git clone git@github.com:user/repo.git

# Add to git config
git config --global core.sshCommand "ssh -i ~/.ssh/id_rsa -F /dev/null"
```

### Solution 4: Copier Workarounds

#### Option A: Use HTTPS with Tokens

```bash
# For GitHub
copier copy https://oauth2:YOUR_GITHUB_TOKEN@github.com/akretion/docky-odoo-template-shared .

# For GitLab
copier copy https://oauth2:YOUR_GITLAB_TOKEN@gitlab.com/akretion/docky-odoo-template-shared .
```

#### Option B: Manual Clone Then Copier

```bash
# Clone template manually to a different location
git clone https://github.com/akretion/docky-odoo-template-shared.git ~/docky-template

# Then use copier with local path
copier copy ~/docky-template .
```

#### Option C: Use Different Temporary Directory

```bash
# Set TMPDIR to a different location
export TMPDIR=$HOME/tmp
mkdir -p $TMPDIR

# Try copier again
copier copy https://github.com/akretion/docky-odoo-template-shared .
```

### Solution 5: Fix SSH Key Permissions

```bash
# Correct SSH directory permissions
chmod 700 ~/.ssh

# Correct SSH key permissions
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub

# Correct authorized_keys permissions
chmod 600 ~/.ssh/authorized_keys

# Correct known_hosts permissions
chmod 644 ~/.ssh/known_hosts
```

## Troubleshooting Steps

### 1. Diagnose SSH Agent Issues

```bash
# Check if SSH agent is running
ps aux | grep ssh-agent

# Check SSH_AUTH_SOCK variable
echo $SSH_AUTH_SOCK

# Check socket file existence
ls -la $SSH_AUTH_SOCK 2>/dev/null || echo "Socket not found"

# Test SSH agent
ssh-add -l
```

### 2. Test SSH Connections

```bash
# Test GitHub SSH
ssh -T git@github.com

# Test GitLab SSH
ssh -T git@gitlab.com

# Test with verbose output
ssh -vvv git@github.com
```

### 3. Check Directory Permissions

```bash
# Check home directory permissions
ls -ld ~

# Check .ssh directory permissions
ls -ld ~/.ssh

# Check key file permissions
ls -la ~/.ssh/id_*

# Check /tmp permissions
ls -ld /tmp
```

### 4. Test Git Operations

```bash
# Test git clone with SSH
GIT_SSH_COMMAND='ssh -v' git clone git@github.com:user/repo.git

# Test git clone with HTTPS
git clone https://github.com/user/repo.git
```

## Environment-Specific Solutions

### Docker Containers

```bash
# Run SSH agent in container
docker run -it \
  -v $SSH_AUTH_SOCK:/ssh-agent \
  -e SSH_AUTH_SOCK=/ssh-agent \
  ubuntu bash

# Or start SSH agent in container
docker run -it ubuntu bash -c "eval \$(ssh-agent -s) && ssh-add"
```

### CI/CD Pipelines

```bash
# GitHub Actions
- name: Setup SSH
  run: |
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    echo "${{ secrets.SSH_PRIVATE_KEY }}" > ~/.ssh/id_rsa
    chmod 600 ~/.ssh/id_rsa
    ssh-keyscan github.com >> ~/.ssh/known_hosts

# GitLab CI
before_script:
  - mkdir -p ~/.ssh
  - chmod 700 ~/.ssh
  - echo "$SSH_PRIVATE_KEY" > ~/.ssh/id_rsa
  - chmod 600 ~/.ssh/id_rsa
  - ssh-keyscan github.com >> ~/.ssh/known_hosts
```

### Windows Subsystem for Linux (WSL)

```bash
# Start SSH agent in WSL
eval "$(ssh-agent -s)"

# Add keys
ssh-add ~/.ssh/id_rsa

# Fix Windows file permissions
chmod 600 ~/.ssh/id_rsa
chmod 700 ~/.ssh
```

## Best Practices

### 1. SSH Key Management

```bash
# Generate new SSH key
ssh-keygen -t ed25519 -C "your_email@example.com"

# Add key to SSH agent
ssh-add ~/.ssh/id_ed25519

# Copy public key to clipboard
xclip -sel clip < ~/.ssh/id_ed25519.pub

# Add to GitHub/GitLab
# Settings → SSH and GPG keys → New SSH key
```

### 2. Multiple SSH Keys

```bash
# Create config file
cat > ~/.ssh/config << 'EOF'
# Personal GitHub
Host github.com-personal
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_rsa_personal
  IdentitiesOnly yes

# Work GitHub
Host github.com-work
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_rsa_work
  IdentitiesOnly yes

# GitLab
Host gitlab.com
  HostName gitlab.com
  User git
  IdentityFile ~/.ssh/id_ed25519_gitlab
  IdentitiesOnly yes
EOF

# Use with git
git clone git@github.com-personal:user/repo.git
```

### 3. Persistent SSH Agent

```bash
# Add to ~/.bashrc or ~/.zshrc
if [ -z "$SSH_AUTH_SOCK" ]; then
   eval "$(ssh-agent -s)"
   ssh-add ~/.ssh/id_rsa 2>/dev/null
fi

# Or use keychain
sudo apt-get install keychain
keychain --eval ~/.ssh/id_rsa
```

## Common Error Patterns

### Pattern 1: Permission Denied in /tmp

**Error:** `unix_listener: cannot bind to path /tmp/ssh-XXXXXX/agent.XXXX: Permission denied`

**Solution:** Use custom socket location or fix /tmp permissions.

### Pattern 2: Copier Template Failures

**Error:** `fatal: Invalid path '/tmp/copier._vcs.clone.XXXXXX/.git': Permission denied`

**Solution:** Use HTTPS URLs, manual clone, or different TMPDIR.

### Pattern 3: SSH Key Too Open

**Error:** `Permissions 0644 for 'id_rsa' are too open.`

**Solution:** `chmod 600 ~/.ssh/id_rsa`

### Pattern 4: Agent Adoption Failed

**Error:** `Agent admitted failure to sign using the key.`

**Solution:** Restart SSH agent and re-add keys.

### Pattern 5: No Such Identity

**Error:** `Could not open a connection to your authentication agent.`

**Solution:** Start SSH agent and set SSH_AUTH_SOCK.

## Reference Files

- `references/ssh-permission-fixes.md` - Common fixes and workarounds
- `references/ssh-diagnostics.md` - Diagnostic commands and scripts
- `references/ssh-config-examples.md` - Configuration file examples

## Triggers

This skill is automatically invoked when you ask about:
- SSH permission issues
- SSH agent problems
- Copier template failures
- Git clone permission errors
- SSH key management
- SSH in restricted environments
- SSH in Docker containers
- SSH in CI/CD pipelines

## See Also

- `docker-docky-management`: Docker and Docky setup patterns
- `gitlab-repo-management`: GitLab repository operations
- `github-repo-management`: GitHub repository operations

[Skill directory: /root/.hermes/skills/devops/ssh-permission-troubleshooting]
Resolve any relative paths in this skill (e.g. `scripts/foo.js`, `templates/config.yaml`) against that directory, then run them with the terminal tool using the absolute path.