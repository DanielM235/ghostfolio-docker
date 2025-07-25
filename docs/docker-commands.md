# Docker Compose Commands & Container Management

Essential Docker commands for managing your Ghostfolio deployment.

## 📋 Table of Contents

- [Service Management](#service-management)
- [Container Access](#container-access)
- [Database Container Access](#database-container-access)
- [Application Container Access](#application-container-access)
- [Redis Container Access](#redis-container-access)
- [Container Health & Debugging](#container-health--debugging)
- [Resource Monitoring](#resource-monitoring)
- [Cleanup Commands](#cleanup-commands)

## 🚀 Service Management

### Basic Operations

```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# Restart all services
docker compose restart

# Restart specific service
docker compose restart ghostfolio
docker compose restart postgres
docker compose restart redis

# Stop and remove everything (including volumes)
docker compose down -v
```

### Status and Information

```bash
# View running services
docker compose ps

# View detailed service info
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

# Show service configuration
docker compose config

# View resource usage
docker compose top
```

## 🔍 Container Access

### Interactive Shell Access

```bash
# Access Ghostfolio application container
docker compose exec ghostfolio sh

# Access PostgreSQL container
docker compose exec postgres bash

# Access Redis container
docker compose exec redis sh

# Access with specific user
docker compose exec --user root ghostfolio sh
```

### Running One-Time Commands

```bash
# Run command without entering container
docker compose exec ghostfolio ls -la /app

# Check container's environment variables
docker compose exec ghostfolio env

# Test network connectivity from container
docker compose exec ghostfolio ping postgres
docker compose exec ghostfolio ping redis
```

## 🗄️ Database Container Access

### PostgreSQL Database Management

```bash
# Access PostgreSQL CLI
docker compose exec postgres psql -U ghostfolio -d ghostfolio

# List all databases
docker compose exec postgres psql -U ghostfolio -l

# Run SQL query directly
docker compose exec postgres psql -U ghostfolio -d ghostfolio -c "SELECT version();"

# Backup database
docker compose exec postgres pg_dump -U ghostfolio ghostfolio > backup.sql

# Check database size
docker compose exec postgres psql -U ghostfolio -d ghostfolio -c "SELECT pg_size_pretty(pg_database_size('ghostfolio'));"
```

### Database File System Exploration

```bash
# Access database container file system
docker compose exec postgres bash

# Navigate to PostgreSQL data directory
cd /var/lib/postgresql/data

# List database files
ls -la

# Check PostgreSQL configuration
cat postgresql.conf

# View log files
tail -f pg_log/postgresql-*.log
```

### Database Connection Testing

```bash
# Test database connection from app container
docker compose exec ghostfolio pg_isready -h postgres -p 5432

# Check database processes
docker compose exec postgres ps aux

# Monitor database activity
docker compose exec postgres psql -U ghostfolio -d ghostfolio -c "SELECT * FROM pg_stat_activity;"
```

## 📱 Application Container Access

### Ghostfolio Application Debugging

```bash
# Access application container
docker compose exec ghostfolio sh

# Check application structure
ls -la /app/

# View application files
cd /app && find . -name "*.json" -o -name "*.js" | head -20

# Check Node.js version and packages
node --version
npm list --depth=0

# Check application logs in container
tail -f /app/logs/*.log
```

### Application Health Checks

```bash
# Test internal health endpoint
docker compose exec ghostfolio wget -qO- http://localhost:3333/api/v1/health

# Check application processes
docker compose exec ghostfolio ps aux

# Monitor application memory usage
docker compose exec ghostfolio cat /proc/meminfo

# Check application configuration
docker compose exec ghostfolio env | grep -E "(DATABASE|REDIS|NODE)"
```

## 📊 Container Health & Debugging

### Health Status Monitoring

```bash
# Check container health status
docker compose ps --filter "health=healthy"
docker compose ps --filter "health=unhealthy"

# Inspect container health checks
docker inspect ghostfolio-ghostfolio-1 | jq '.[].State.Health'

# View health check logs
docker inspect ghostfolio-ghostfolio-1 | jq '.[].State.Health.Log'
```

### Container Resource Usage

```bash
# Monitor real-time container stats
docker stats

# View specific container stats
docker stats ghostfolio-ghostfolio-1 ghostfolio-postgres-1 ghostfolio-redis-1

# Check container resource limits
docker inspect ghostfolio-ghostfolio-1 | jq '.[].HostConfig.Memory'
docker inspect ghostfolio-ghostfolio-1 | jq '.[].HostConfig.CpuShares'
```

### Network Debugging

```bash
# List Docker networks
docker network ls

# Inspect project network
docker network inspect ghostfolio-docker_default

# Test container connectivity
docker compose exec ghostfolio ping postgres
docker compose exec ghostfolio nslookup postgres
docker compose exec ghostfolio telnet postgres 5432

# Check open ports in container
docker compose exec ghostfolio netstat -tuln
```

### Container Process Monitoring

```bash
# View running processes in all containers
docker compose top

# View processes in specific container
docker compose exec ghostfolio ps aux
docker compose exec postgres ps aux

# Monitor system calls (for debugging)
docker compose exec ghostfolio strace -p 1

# Check container resource usage
docker compose exec ghostfolio cat /proc/1/status
```

## 🚨 Troubleshooting Common Issues

### Container Won't Start

```bash
# Check detailed container status
docker compose ps -a

# View container exit codes
docker compose ps --format "table {{.Names}}\t{{.Status}}"

# Inspect failed container
docker inspect <container_name> | jq '.[].State'

# Check for port conflicts
netstat -tuln | grep :8061
lsof -i :8061
```

### Service Dependencies

```bash
# Check service startup order
docker compose config --services

# View service dependencies
docker compose config | grep -A 5 -B 5 depends_on

# Start services in specific order
docker compose up -d postgres redis
sleep 10
docker compose up -d ghostfolio
```

### Volume and Permission Issues

```bash
# Check volume mounts
docker compose exec ghostfolio mount | grep /app
docker compose exec postgres mount | grep /var/lib/postgresql

# Check file permissions in volumes
docker compose exec postgres ls -la /var/lib/postgresql/data
docker compose exec ghostfolio ls -la /app/upload

# Fix permission issues
docker compose exec --user root postgres chown -R postgres:postgres /var/lib/postgresql/data
docker compose exec --user root ghostfolio chown -R node:node /app/upload
```

## 🧹 Cleanup Commands

### Image and Container Cleanup

```bash
# Remove stopped containers
docker compose rm

# Remove unused images
docker image prune

# Remove unused volumes
docker volume prune

# Complete system cleanup (BE CAREFUL!)
docker system prune -a

# Remove only project-related resources
docker compose down --rmi all --volumes --remove-orphans
```

### Log Cleanup

```bash
# Truncate container logs
truncate -s 0 /var/lib/docker/containers/*/*-json.log

# Set log rotation (add to docker-compose.yml)
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

## 🔧 Advanced Commands

### Container Inspection

```bash
# View container environment variables
docker compose exec ghostfolio env | sort

# Check container filesystem changes
docker diff ghostfolio-ghostfolio-1

# Export container filesystem
docker export ghostfolio-ghostfolio-1 > ghostfolio-container.tar

# View container metadata
docker inspect ghostfolio-ghostfolio-1 | jq '.[].Config'
```

### Performance Monitoring

```bash
# Monitor container I/O
docker exec ghostfolio-ghostfolio-1 iostat -x 1

# Monitor network traffic
docker exec ghostfolio-ghostfolio-1 iftop

# Check container memory maps
docker exec ghostfolio-ghostfolio-1 cat /proc/1/maps

# Monitor file descriptor usage
docker exec ghostfolio-ghostfolio-1 lsof -p 1
```

## 📝 Quick Reference

| Command | Description |
|---------|-------------|
| `docker compose logs -f <service>` | Follow logs for specific service |
| `docker compose exec <service> sh` | Access service container |
| `docker compose restart <service>` | Restart specific service |
| `docker compose ps` | Show service status |
| `docker compose top` | Show running processes |
| `docker stats` | Show resource usage |
| `docker system df` | Show disk usage |
| `docker compose config` | Validate and view configuration |

---

💡 **Pro Tip**: Create aliases for frequently used commands:
```bash
alias dcu="docker compose up -d"
alias dcd="docker compose down"
alias dcl="docker compose logs -f"
alias dcp="docker compose ps"
```
