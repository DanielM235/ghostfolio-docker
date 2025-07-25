# File Permissions & Access Rights on Debian

Comprehensive guide to managing file permissions, ownership, and access rights for your Ghostfolio deployment on Debian systems.

## 📋 Table of Contents

- [Understanding Linux Permissions](#understanding-linux-permissions)
- [Docker & File Permissions](#docker--file-permissions)
- [Database File Permissions](#database-file-permissions)
- [Web Server Permissions](#web-server-permissions)
- [Security Best Practices](#security-best-practices)
- [Troubleshooting Common Issues](#troubleshooting-common-issues)
- [Advanced Permission Management](#advanced-permission-management)
- [Automated Permission Scripts](#automated-permission-scripts)

## 🔐 Understanding Linux Permissions

### Basic Permission Concepts

```bash
# View file permissions
ls -la

# Permission format: -rwxrwxrwx
# Position: -uuugggooo
# - = file type (- = file, d = directory, l = symlink)
# uuu = user/owner permissions
# ggg = group permissions  
# ooo = other/world permissions
# rwx = read, write, execute

# Numeric representation
# 4 = read (r)
# 2 = write (w)
# 1 = execute (x)
# 755 = rwxr-xr-x (owner: rwx, group: r-x, others: r-x)
# 644 = rw-r--r-- (owner: rw-, group: r--, others: r--)
# 600 = rw------- (owner: rw-, group: ---, others: ---)
```

### Essential Permission Commands

```bash
# Change file permissions
chmod 755 script.sh              # Make script executable
chmod 644 config.txt             # Standard file permissions
chmod 600 .env                   # Secure config file
chmod 700 private_directory/     # Private directory

# Change ownership
chown user:group filename
chown ghostfolio:ghostfolio data/
chown -R www-data:www-data /var/www/

# Change group only
chgrp docker docker-compose.yml

# Special permissions
chmod +x script.sh               # Add execute permission
chmod -w readonly.txt            # Remove write permission
chmod u+rw,g+r,o-rwx secure.conf # Detailed permission setting
```

### Understanding User and Group Context

```bash
# Check current user and groups
whoami
id
groups

# Check user information
id username
getent passwd username
getent group groupname

# Add user to group
sudo usermod -aG docker $USER
sudo usermod -aG www-data $USER

# Create new user for application
sudo useradd -r -s /bin/false ghostfolio
sudo usermod -aG docker ghostfolio
```

## 🐳 Docker & File Permissions

### Container User Mapping

```bash
# Check Docker container user mapping
docker compose exec ghostfolio id
docker compose exec postgres id

# View process ownership inside container
docker compose exec ghostfolio ps aux
docker compose exec postgres ps aux

# Check file ownership in volumes
docker compose exec ghostfolio ls -la /app/
docker compose exec postgres ls -la /var/lib/postgresql/data/
```

### Volume Permission Issues

```bash
# Common volume permission problems and solutions

# Problem: Permission denied when container tries to write to volume
# Solution 1: Fix host directory permissions
sudo chown -R $USER:$USER /opt/ghostfolio/data/
chmod -R 755 /opt/ghostfolio/data/

# Solution 2: Match container user UID with host user
docker compose exec ghostfolio id  # Get container UID
sudo chown -R 1000:1000 /opt/ghostfolio/data/  # Match UID

# Solution 3: Use Docker user mapping in compose file
# Add to docker-compose.yml:
user: "${UID}:${GID}"
# Then export UID and GID in .env:
echo "UID=$(id -u)" >> .env
echo "GID=$(id -g)" >> .env
```

### Docker Compose User Configuration

```yaml
# Method 1: Set user in docker-compose.yml
services:
  ghostfolio:
    image: ghostfolio/ghostfolio:2.184.0
    user: "${UID:-1000}:${GID:-1000}"
    volumes:
      - ${DATA_BASE_PATH}/data/storage:/app/upload

# Method 2: Use init container to fix permissions
services:
  permissions-fix:
    image: alpine:latest
    user: root
    volumes:
      - ${DATA_BASE_PATH}/data:/data
    command: |
      sh -c "
        chown -R 1000:1000 /data
        chmod -R 755 /data
      "

  ghostfolio:
    image: ghostfolio/ghostfolio:2.184.0
    depends_on:
      - permissions-fix
```

## 🗄️ Database File Permissions

### PostgreSQL Permissions

```bash
# Standard PostgreSQL permissions
sudo chown -R postgres:postgres /opt/ghostfolio/data/db/postgre/
chmod 700 /opt/ghostfolio/data/db/postgre/             # Database directory
chmod 600 /opt/ghostfolio/data/db/postgre/*            # Database files

# Fix PostgreSQL permission issues
docker compose stop postgres

# Fix ownership from host
sudo chown -R 999:999 /opt/ghostfolio/data/db/postgre/  # PostgreSQL container UID

# Or fix from container
docker compose run --rm --user root postgres chown -R postgres:postgres /var/lib/postgresql/data
docker compose start postgres

# Verify permissions
docker compose exec postgres ls -la /var/lib/postgresql/data/
```

### Database Directory Structure

```bash
# Proper PostgreSQL directory permissions
/opt/ghostfolio/data/db/
├── postgre/                     # 700 (drwx------)
│   ├── base/                    # 700 (drwx------)
│   ├── global/                  # 700 (drwx------)
│   ├── pg_wal/                  # 700 (drwx------)
│   ├── postgresql.conf          # 600 (-rw-------)
│   └── pg_hba.conf             # 600 (-rw-------)

# Create proper structure
sudo mkdir -p /opt/ghostfolio/data/db/postgre
sudo chown -R 999:999 /opt/ghostfolio/data/db/postgre
sudo chmod 700 /opt/ghostfolio/data/db/postgre
```

### Redis Permissions

```bash
# Redis permissions
sudo chown -R 999:999 /opt/ghostfolio/data/cache/redis/
chmod 755 /opt/ghostfolio/data/cache/redis/             # Redis directory
chmod 644 /opt/ghostfolio/data/cache/redis/*            # Redis files

# Redis doesn't require strict permissions like PostgreSQL
# But should still be owned by redis user (UID 999 in container)

# Verify Redis permissions
docker compose exec redis ls -la /data/
docker compose exec redis id
```

## 🌐 Web Server Permissions

### Nginx/Reverse Proxy Permissions

```bash
# If using nginx reverse proxy
sudo chown -R www-data:www-data /var/www/
sudo chmod -R 755 /var/www/

# SSL certificate permissions
sudo chown root:root /etc/ssl/certs/ghostfolio.*
sudo chmod 644 /etc/ssl/certs/ghostfolio.crt
sudo chmod 600 /etc/ssl/private/ghostfolio.key

# Nginx configuration permissions
sudo chown root:root /etc/nginx/sites-available/ghostfolio
sudo chmod 644 /etc/nginx/sites-available/ghostfolio
```

### Application File Permissions

```bash
# Ghostfolio application permissions
sudo chown -R $USER:$USER /opt/ghostfolio/
chmod 755 /opt/ghostfolio/                              # Main directory
chmod 755 /opt/ghostfolio/data/                         # Data directory
chmod 755 /opt/ghostfolio/data/storage/                 # Upload directory
chmod 644 /opt/ghostfolio/data/storage/*                # Uploaded files

# Log file permissions
sudo chown -R $USER:$USER /opt/ghostfolio/logs/
chmod 755 /opt/ghostfolio/logs/                         # Log directory
chmod 644 /opt/ghostfolio/logs/*.log                    # Log files
```

## 🔒 Security Best Practices

### Secure File Permissions

```bash
# Environment files (contain secrets)
chmod 600 .env .db.env                                  # Owner read/write only
chown $USER:$USER .env .db.env

# Scripts
chmod 755 deploy.sh backup.sh update.sh                # Executable by owner
chmod 644 docker-compose.yml                           # Readable by all

# Private keys
chmod 600 ~/.ssh/id_rsa                                # SSH private key
chmod 644 ~/.ssh/id_rsa.pub                            # SSH public key
chmod 700 ~/.ssh/                                      # SSH directory

# Configuration directories
chmod 755 /opt/ghostfolio/                             # Accessible
chmod 700 /opt/ghostfolio/data/db/                     # Database private
chmod 755 /opt/ghostfolio/data/storage/                # Uploads accessible
```

### SELinux Considerations (if enabled)

```bash
# Check if SELinux is enabled
sestatus

# Set SELinux context for Docker volumes
sudo setsebool -P container_manage_cgroup true
sudo semanage fcontext -a -t container_file_t "/opt/ghostfolio(/.*)?"
sudo restorecon -R /opt/ghostfolio/

# Allow Docker to access host directories
sudo chcon -Rt svirt_sandbox_file_t /opt/ghostfolio/
```

### AppArmor Configuration

```bash
# Check AppArmor status
sudo apparmor_status

# Docker with AppArmor
sudo aa-status | grep docker

# Create custom AppArmor profile for containers if needed
sudo nano /etc/apparmor.d/docker-ghostfolio
```

## 🔧 Troubleshooting Common Issues

### Permission Denied Errors

```bash
# Error: Permission denied writing to volume
# Diagnosis:
docker compose logs ghostfolio | grep -i "permission denied"
docker compose exec ghostfolio ls -la /app/upload/

# Solutions:
# 1. Fix host directory ownership
sudo chown -R $USER:docker /opt/ghostfolio/data/storage/
chmod -R 755 /opt/ghostfolio/data/storage/

# 2. Fix container user mapping
echo "UID=$(id -u)" >> .env
echo "GID=$(id -g)" >> .env
# Add user: "${UID}:${GID}" to docker-compose.yml

# 3. Use init container
docker compose run --rm --user root ghostfolio chown -R node:node /app/upload
```

### Database Permission Issues

```bash
# PostgreSQL won't start - permission issues
# Diagnosis:
docker compose logs postgres | grep -i "permission\|denied"

# Common solutions:
# 1. Fix PostgreSQL data directory
sudo chown -R 999:999 /opt/ghostfolio/data/db/postgre/
sudo chmod 700 /opt/ghostfolio/data/db/postgre/

# 2. Reset PostgreSQL data (DESTROYS DATA!)
docker compose down
sudo rm -rf /opt/ghostfolio/data/db/postgre/*
docker compose up -d postgres

# 3. Fix from inside container
docker compose exec --user root postgres chown -R postgres:postgres /var/lib/postgresql/data
docker compose restart postgres
```

### File Upload Issues

```bash
# Ghostfolio can't save uploaded files
# Diagnosis:
docker compose exec ghostfolio ls -la /app/upload/
docker compose exec ghostfolio touch /app/upload/test.txt

# Solutions:
# 1. Fix upload directory permissions
sudo chown -R 1000:1000 /opt/ghostfolio/data/storage/
chmod -R 755 /opt/ghostfolio/data/storage/

# 2. Check volume mount
docker compose exec ghostfolio mount | grep upload

# 3. Restart with proper permissions
docker compose down
sudo chown -R $USER:docker /opt/ghostfolio/data/storage/
docker compose up -d
```

## 🏗️ Advanced Permission Management

### Access Control Lists (ACLs)

```bash
# Install ACL tools
sudo apt update && sudo apt install acl

# Set default ACLs
sudo setfacl -d -m u::rwx,g::r-x,o::--- /opt/ghostfolio/data/
sudo setfacl -d -m u:www-data:r-x /opt/ghostfolio/data/storage/

# View ACLs
getfacl /opt/ghostfolio/data/

# Set specific user permissions
sudo setfacl -m u:ghostfolio:rwx /opt/ghostfolio/data/storage/
sudo setfacl -m g:docker:r-x /opt/ghostfolio/data/
```

### Capabilities Management

```bash
# View process capabilities
sudo apt install libcap2-bin
getcap /usr/bin/docker

# Set capabilities for specific binaries
sudo setcap 'cap_net_bind_service=+ep' /usr/local/bin/ghostfolio-server

# Docker capabilities
# In docker-compose.yml:
cap_add:
  - NET_ADMIN
  - SYS_ADMIN
cap_drop:
  - ALL
```

### User Namespaces

```bash
# Enable Docker user namespaces
# Edit /etc/docker/daemon.json
{
  "userns-remap": "default"
}

# Restart Docker
sudo systemctl restart docker

# This maps container root to unprivileged host user
# Container UID 0 maps to host UID 165536
```

## 🤖 Automated Permission Scripts

### Permission Audit Script

```bash
cat << 'EOF' > check-permissions.sh
#!/bin/bash

echo "=== Ghostfolio Permission Audit ==="
echo "Date: $(date)"
echo

# Check script permissions
echo "Script Permissions:"
ls -la *.sh

echo
echo "Environment File Permissions:"
ls -la .env* 2>/dev/null || echo "No environment files found"

echo
echo "Data Directory Permissions:"
if [ -d "/opt/ghostfolio" ]; then
    sudo ls -la /opt/ghostfolio/data/
else
    echo "Ghostfolio data directory not found"
fi

echo
echo "Container User Information:"
docker compose exec ghostfolio id 2>/dev/null || echo "Ghostfolio container not running"
docker compose exec postgres id 2>/dev/null || echo "PostgreSQL container not running"
docker compose exec redis id 2>/dev/null || echo "Redis container not running"

echo
echo "Volume Mount Information:"
docker compose exec ghostfolio mount | grep -E "(app|data)" 2>/dev/null || echo "No volume mounts found"

echo
echo "Permission Issues Detection:"
# Check for common permission problems
if docker compose logs ghostfolio 2>/dev/null | grep -i "permission denied" >/dev/null; then
    echo "❌ Permission denied errors found in Ghostfolio logs"
else
    echo "✅ No permission denied errors in Ghostfolio logs"
fi

if docker compose logs postgres 2>/dev/null | grep -i "permission denied" >/dev/null; then
    echo "❌ Permission denied errors found in PostgreSQL logs"
else
    echo "✅ No permission denied errors in PostgreSQL logs"
fi
EOF

chmod +x check-permissions.sh
```

### Permission Fix Script

```bash
cat << 'EOF' > fix-permissions.sh
#!/bin/bash

echo "=== Ghostfolio Permission Fix Script ==="
echo "This script will fix common permission issues"
echo

# Check if running as root or with sudo
if [[ $EUID -eq 0 ]]; then
    echo "❌ Don't run this script as root directly"
    echo "Run with: ./fix-permissions.sh"
    exit 1
fi

# Check for sudo access
if ! sudo -n true 2>/dev/null; then
    echo "This script requires sudo access"
    exit 1
fi

read -p "Continue with permission fixes? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted"
    exit 1
fi

echo "Stopping services..."
docker compose down

echo "Fixing script permissions..."
chmod 755 *.sh
chmod 644 docker-compose.yml *.yml *.md
chmod 600 .env .db.env 2>/dev/null || echo "Environment files not found"

echo "Fixing data directory permissions..."
if [ -d "/opt/ghostfolio" ]; then
    sudo chown -R $USER:docker /opt/ghostfolio/
    sudo chmod 755 /opt/ghostfolio/
    sudo chmod 755 /opt/ghostfolio/data/
    sudo chmod 755 /opt/ghostfolio/data/storage/
    sudo chmod 700 /opt/ghostfolio/data/db/postgre/ 2>/dev/null || echo "PostgreSQL directory not found"
    sudo chmod 755 /opt/ghostfolio/data/cache/redis/ 2>/dev/null || echo "Redis directory not found"
    sudo chmod 755 /opt/ghostfolio/logs/ 2>/dev/null || echo "Logs directory not found"
    
    # Fix PostgreSQL specific permissions
    if [ -d "/opt/ghostfolio/data/db/postgre" ]; then
        sudo chown -R 999:999 /opt/ghostfolio/data/db/postgre/
        sudo chmod 700 /opt/ghostfolio/data/db/postgre/
    fi
    
    # Fix Redis specific permissions
    if [ -d "/opt/ghostfolio/data/cache/redis" ]; then
        sudo chown -R 999:999 /opt/ghostfolio/data/cache/redis/
    fi
    
    echo "✅ Data directory permissions fixed"
else
    echo "⚠️  Data directory not found, will be created on next startup"
fi

echo "Starting services..."
docker compose up -d

echo "✅ Permission fix completed"
echo "Check logs with: docker compose logs -f"
EOF

chmod +x fix-permissions.sh
```

### Daily Permission Monitor

```bash
cat << 'EOF' > monitor-permissions.sh
#!/bin/bash

# Daily permission monitoring script
LOG_FILE="/var/log/ghostfolio-permissions.log"
DATE=$(date)

{
    echo "[$DATE] Permission Check"
    
    # Check for permission denied in logs
    if docker compose logs --since 24h 2>/dev/null | grep -i "permission denied" >/dev/null; then
        echo "❌ Permission denied errors found in last 24h"
        docker compose logs --since 24h | grep -i "permission denied" | tail -5
    else
        echo "✅ No permission denied errors in last 24h"
    fi
    
    # Check data directory ownership
    if [ -d "/opt/ghostfolio/data" ]; then
        OWNER=$(stat -c '%U:%G' /opt/ghostfolio/data/)
        echo "Data directory owner: $OWNER"
        
        if [[ "$OWNER" != "$USER:docker" ]] && [[ "$OWNER" != "$USER:$USER" ]]; then
            echo "⚠️  Unexpected data directory ownership: $OWNER"
        fi
    fi
    
    echo "---"
} >> "$LOG_FILE"

# Rotate log file if it gets too large
if [ -f "$LOG_FILE" ] && [ $(stat -c%s "$LOG_FILE") -gt 1048576 ]; then  # 1MB
    sudo mv "$LOG_FILE" "${LOG_FILE}.old"
fi
EOF

chmod +x monitor-permissions.sh

# Add to crontab for daily monitoring
echo "0 6 * * * /path/to/ghostfolio-docker/monitor-permissions.sh" | crontab -
```

## 📝 Quick Reference

### Common Permission Values

| Permission | Numeric | Symbolic | Use Case |
|------------|---------|----------|----------|
| 755 | rwxr-xr-x | Directories, scripts | Standard directory/executable |
| 644 | rw-r--r-- | Regular files | Standard file |
| 600 | rw------- | Secrets, keys | Private files |
| 700 | rwx------ | Private directories | Database directories |
| 640 | rw-r----- | Config files | Group-readable configs |

### Docker UID/GID Mapping

| Container | Default UID | Host Mapping | Purpose |
|-----------|-------------|--------------|---------|
| Ghostfolio | 1000 | $USER | Application user |
| PostgreSQL | 999 | postgres | Database user |
| Redis | 999 | redis | Cache user |
| nginx | 33 | www-data | Web server |

### Essential Commands

```bash
# Quick permission fixes
chmod 755 $(find . -type d)              # Fix directory permissions
chmod 644 $(find . -type f -name "*.yml") # Fix YAML files
chmod 600 .env .db.env                   # Secure environment files
chmod +x *.sh                           # Make scripts executable

# Ownership fixes
sudo chown -R $USER:docker /opt/ghostfolio/
sudo chown -R 999:999 /opt/ghostfolio/data/db/postgre/

# Permission checking
ls -la                                   # List permissions
stat filename                           # Detailed file info
id username                             # User/group info
getfacl filename                        # ACL permissions
```

---

💡 **Security Tip**: Always use the principle of least privilege - grant only the minimum permissions necessary for the application to function properly. Regularly audit permissions and remove unnecessary access rights.
