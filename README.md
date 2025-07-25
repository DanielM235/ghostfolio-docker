# Ghostfolio Docker Deployment

Production-ready Docker Compose configuration for self-hosting [Ghostfolio](https://github.com/ghostfolio/ghostfolio), an open-source wealth management software.

**Current Version:** v1.0.0 | **Ghostfolio Version:** 2.184.0

## 🚀 Quick Start

1. **Clone and setup**:
   ```bash
   git clone <repository-url>
   cd ghostfolio-docker
   ```

2. **Check version information**:
   ```bash
   ./deploy.sh --version
   ```

3. **Configure environment**:
   ```bash
   cp .env.example .env
   cp .db.env.example .db.env
   # Edit both files and configure your specific settings
   ```

4. **Deploy**:
   ```bash
   ./deploy.sh
   ```

5. **Access**: Open http://localhost:8061 (or your configured port) and create your admin account

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Management Scripts](#management-scripts)
- [Backup & Recovery](#backup--recovery)
- [Updating](#updating)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)
- [Security](#security)

## 🏗️ Overview

This deployment provides:

- **Configurable Ghostfolio version** (default: v2.184.0, pinned for stability)
- **PostgreSQL 16** database with optimized configuration
- **Redis 7** for caching and session management
- **Flexible configuration** via environment variables
- **Automated backup and update scripts**
- **Production-ready security settings**
- **Comprehensive monitoring and logging**

## 🔧 Architecture

```
nginx (your reverse proxy) → localhost:${EXTERNAL_PORT} → Ghostfolio Container
                                            ↓
                                    Internal Network
                                    ↙              ↘
                            PostgreSQL        Redis
                           (database)        (cache)
```

### Services

| Service | Image | Purpose | Port |
|---------|-------|---------|------|
| Ghostfolio | `ghostfolio/ghostfolio:${GHOSTFOLIO_VERSION}` | Web application | ${EXTERNAL_PORT} |
| PostgreSQL | `postgres:${POSTGRES_VERSION}-alpine` | Database | Internal only |
| Redis | `redis:${REDIS_VERSION}-alpine` | Cache | Internal only |

### Volume Structure

```
${DATA_BASE_PATH}/
├── data/
│   ├── db/postgre/        # PostgreSQL data
│   ├── cache/redis/       # Redis persistence
│   └── storage/           # User files
└── logs/                  # Application logs
    ├── postgres/
    └── redis/
```

## 📦 Prerequisites

- **Docker** 20.10+ and **Docker Compose** v2
- **sudo privileges** for directory creation
- **Minimum 2GB RAM** and **10GB disk space**
- **nginx** configured for reverse proxy to localhost:8061

## 🛠️ Installation

### 1. Environment Setup

Copy and configure environment files:

```bash
# Copy environment templates
cp .env.example .env
cp .db.env.example .db.env
```

Generate secure secrets:

```bash
# Generate ACCESS_TOKEN_SALT (64 chars hex)
openssl rand -hex 32

# Generate JWT_SECRET_KEY
openssl rand -base64 32

# Generate database passwords  
openssl rand -base64 24
```

### 2. Directory Structure

The deployment script will create the required directory structure:

```bash
sudo mkdir -p ${DATA_BASE_PATH}/{data/{db/postgre,cache/redis,storage},logs/{postgres,redis}}
```

### 3. Deployment

Use the automated deployment script:

```bash
# Full deployment with backup
./deploy.sh

# Setup only (no service start)
./deploy.sh --setup-only

# Start services only (skip setup)
./deploy.sh --start-only
```

## ⚙️ Configuration

### Environment Variables

#### Project Settings (`.env`)

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `PROJECT_NAME` | Project identifier | `ghostfolio` | `my-portfolio` |
| `BASE_DOMAIN` | Application domain | `localhost` | `portfolio.example.com` |
| `DATA_BASE_PATH` | Data storage path | `/opt/ghostfolio` | `/var/www/portfolio` |
| `EXTERNAL_PORT` | External port | `8061` | `8080` |
| `GHOSTFOLIO_VERSION` | App version | `2.184.0` | `2.185.0` |
| `POSTGRES_VERSION` | PostgreSQL version | `16` | `15` |
| `REDIS_VERSION` | Redis version | `7` | `6` |
| `DOCKER_SUBNET` | Internal subnet | `172.20.0.0/16` | `172.21.0.0/16` |
| `DOCKER_GATEWAY` | Network gateway | `172.20.0.1` | `172.21.0.1` |

#### Application Settings (`.env`)

| Variable | Description | Example |
|----------|-------------|---------|
| `NODE_ENV` | Runtime environment | `production` |
| `HOST` | Application host | `0.0.0.0` |
| `PORT` | Internal port | `3333` |
| `ACCESS_TOKEN_SALT` | Token salt (security critical) | `abc123...` |
| `JWT_SECRET_KEY` | JWT secret (security critical) | `xyz789...` |
| `DATABASE_URL` | PostgreSQL connection | Auto-generated |
| `REDIS_HOST` | Redis hostname | `redis` |
| `REDIS_PORT` | Redis port | `6379` |
| `LOG_LEVELS` | Logging levels | `["error","warn","log"]` |

#### Database Settings (`.db.env`)

| Variable | Description | Example |
|----------|-------------|---------|
| `POSTGRES_USER` | Database username | `ghostfolio_user` |
| `POSTGRES_PASSWORD` | Database password | Strong password |
| `POSTGRES_DB` | Database name | `ghostfolio_db` |
| `REDIS_PASSWORD` | Redis password | Strong password |

### nginx Configuration

Add to your nginx configuration:

```nginx
server {
    listen 80;
    server_name ${BASE_DOMAIN};
    
    location / {
        proxy_pass http://localhost:${EXTERNAL_PORT};
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

## 🔨 Management Scripts

### Deploy Script (`./deploy.sh`)

Automated deployment with directory setup and service management:

```bash
./deploy.sh                 # Full deployment
./deploy.sh --setup-only     # Setup directories and files only
./deploy.sh --start-only     # Start services only
./deploy.sh --version       # Show version information
./deploy.sh --help          # Show help
```

### Backup Script (`./backup.sh`)

Comprehensive backup solution:

```bash
./backup.sh                 # Full backup
./backup.sh --db-only       # Database only
./backup.sh --files-only    # User files only
./backup.sh --compress      # Create compressed archive
./backup.sh --version       # Show version information
./backup.sh --help         # Show help
```

### Update Script (`./update.sh`)

Safe update procedures:

```bash
./update.sh --backup-first           # Update with backup
./update.sh --to-version 2.185.0     # Update to specific version
./update.sh --dry-run               # Preview changes
./update.sh --rollback              # Rollback to previous version
./update.sh --version               # Show version information
./update.sh --help                  # Show help
```

## 💾 Backup & Recovery

### Automated Backups

Create scheduled backups with cron:

```bash
# Daily backup at 2 AM
0 2 * * * /path/to/ghostfolio-docker/backup.sh --compress

# Weekly full backup
0 3 * * 0 /path/to/ghostfolio-docker/backup.sh --compress
```

### Manual Backup

```bash
# Create immediate backup
./backup.sh --compress

# Database only backup
./backup.sh --db-only

# Files only backup  
./backup.sh --files-only
```

### Recovery Process

1. **Stop services**:
   ```bash
   docker compose down
   ```

2. **Restore data**:
   ```bash
   # Restore PostgreSQL
   docker compose exec postgres psql -U $POSTGRES_USER -d $POSTGRES_DB < backup.sql
   
   # Restore files
   cp -r backup/storage/* ${DATA_BASE_PATH}/data/storage/
   ```

3. **Start services**:
   ```bash
   docker compose up -d
   ```

## 🔄 Updating

### Safe Update Process

1. **Check current version**:
   ```bash
   ./update.sh --dry-run
   ```

2. **Update with backup**:
   ```bash
   ./update.sh --backup-first
   ```

3. **Update to specific version**:
   ```bash
   ./update.sh --to-version 2.185.0 --backup-first
   ```

### Rollback if Needed

```bash
./update.sh --rollback
```

## 📊 Monitoring

### Service Status

```bash
# Check all services
docker compose ps

# View logs
docker compose logs -f

# Service-specific logs
docker compose logs -f ghostfolio
docker compose logs -f postgres
docker compose logs -f redis
```

### Health Checks

```bash
# Application health
curl -f http://localhost:${EXTERNAL_PORT}/api/v1/health

# Database health
docker compose exec postgres pg_isready

# Redis health
docker compose exec redis redis-cli ping
```

### Resource Monitoring

```bash
# Container resource usage
docker stats

# Disk usage
du -sh ${DATA_BASE_PATH}/*

# Log sizes
find ${DATA_BASE_PATH}/logs -name "*.log" -exec du -sh {} \;
```

## 🐛 Troubleshooting

### Common Issues

#### Services Won't Start

```bash
# Check Docker daemon
sudo systemctl status docker

# Check compose file syntax
docker compose config

# View detailed logs
docker compose logs --details
```

#### Database Connection Issues

```bash
# Test database connection
docker compose exec postgres psql -U $POSTGRES_USER -d $POSTGRES_DB -c "SELECT 1;"

# Check database logs
docker compose logs postgres

# Verify environment variables
docker compose exec ghostfolio env | grep DATABASE
```

#### Performance Issues

```bash
# Check resource usage
docker stats

# Analyze slow queries
docker compose exec postgres psql -U $POSTGRES_USER -d $POSTGRES_DB -c "SELECT * FROM pg_stat_activity;"

# Redis performance
docker compose exec redis redis-cli info stats
```

#### Port Conflicts

```bash
# Check port usage
sudo netstat -tulpn | grep :${EXTERNAL_PORT}

# Change port in .env if needed
EXTERNAL_PORT=8062  # Use different external port
```

### Log Analysis

```bash
# Application errors
docker compose logs ghostfolio | grep -i error

# Database issues
docker compose logs postgres | grep -i error

# Cache issues
docker compose logs redis | grep -i error
```

## 🔒 Security

### File Permissions

```bash
# Secure environment files
chmod 600 .env .db.env

# Secure data directories
chmod 700 ${DATA_BASE_PATH}/data/db/postgre
chmod 700 ${DATA_BASE_PATH}/data/cache/redis
```

### Network Security

- Services communicate on isolated Docker network
- Only Ghostfolio app exposed to host (port 8061)
- nginx handles SSL termination and public access
- Database and Redis not directly accessible from outside

### Regular Security Tasks

1. **Update passwords quarterly**
2. **Monitor access logs**
3. **Update container images monthly**
4. **Review user accounts in Ghostfolio**
5. **Backup encryption keys securely**

## ℹ️ Version Information

### Project Versioning

This project follows [Semantic Versioning](https://semver.org/). Check version information:

```bash
./deploy.sh --version     # Show deployment script version
./backup.sh --version     # Show backup script version  
./update.sh --version     # Show update script version
```

### Ghostfolio Version Management

- **Current Version**: Pinned to 2.184.0 (tested and stable)
- **Update Strategy**: Use `./update.sh` for safe version updates
- **Version Control**: All versions tracked in `CHANGELOG.md`

### Compatibility Matrix

| Project Version | Ghostfolio Version | Docker Compose | PostgreSQL | Redis |
|----------------|-------------------|----------------|------------|-------|
| 1.0.0          | 2.184.0          | 3.8+          | 16        | 7     |

## 📝 Additional Notes

### Production Considerations

- **SSL/TLS**: Configure nginx with SSL certificates
- **Firewall**: Restrict access to port 8061 from nginx only
- **Monitoring**: Set up log aggregation and alerting
- **Backups**: Test restore procedures regularly
- **Updates**: Test in staging environment first

### Development vs Production

- **Development**: Use `latest` tags, relaxed security
- **Production**: Pin versions, enforce security, enable monitoring

### Documentation

Comprehensive guides are available in the [`docs/`](docs/) directory:

- 🐳 **[Docker Commands](docs/docker-commands.md)** - Container management and debugging
- 🔗 **[Redis Management](docs/redis-management.md)** - Cache configuration and optimization  
- 📊 **[Logging & Debugging](docs/logging-debugging.md)** - Troubleshooting and monitoring
- ✏️ **[Text Editors & Tools](docs/editors-tools.md)** - Development environment setup
- 🔐 **[Permissions Guide](docs/permissions-guide.md)** - File access and security
- ⚡ **[Advanced Optimization](docs/advanced-optimization.md)** - Performance and production hardening

See the [Documentation Index](docs/README.md) for a complete overview.

### Support

- **Ghostfolio Documentation**: https://github.com/ghostfolio/ghostfolio
- **Docker Compose Reference**: https://docs.docker.com/compose/
- **PostgreSQL Documentation**: https://www.postgresql.org/docs/
- **Redis Documentation**: https://redis.io/documentation

---

**⚠️ Important**: Always test updates in a development environment before applying to production. Keep your environment files secure and never commit them to version control.
