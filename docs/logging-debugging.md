# Logging & Debugging Guide

Comprehensive guide to logging, debugging, and troubleshooting your Ghostfolio deployment.

## 📋 Table of Contents

- [Docker Logs](#docker-logs)
- [Application Logs](#application-logs)
- [Database Logs](#database-logs)
- [System Logs](#system-logs)
- [Log Analysis Tools](#log-analysis-tools)
- [Real-time Monitoring](#real-time-monitoring)
- [Log Rotation & Management](#log-rotation--management)
- [Debugging Workflows](#debugging-workflows)

## 📊 Docker Logs

### Basic Log Commands

```bash
# View logs for all services
docker compose logs

# Follow logs in real-time
docker compose logs -f

# View logs for specific service
docker compose logs ghostfolio
docker compose logs postgres
docker compose logs redis

# Follow specific service logs
docker compose logs -f ghostfolio

# Show timestamps
docker compose logs -t ghostfolio

# Show last N lines
docker compose logs --tail 50 ghostfolio

# Show logs since specific time
docker compose logs --since "2024-01-01T10:00:00" ghostfolio
docker compose logs --since "1h" ghostfolio
```

### Advanced Log Filtering

```bash
# Multiple services
docker compose logs -f ghostfolio postgres

# Grep for specific patterns
docker compose logs ghostfolio | grep -i error
docker compose logs ghostfolio | grep -i "database"
docker compose logs ghostfolio | grep -E "(error|warn|fail)"

# Show logs with context lines
docker compose logs ghostfolio | grep -A 5 -B 5 "error"

# Filter by log level
docker compose logs ghostfolio | grep -E "(ERROR|WARN|INFO|DEBUG)"

# Exclude noise
docker compose logs ghostfolio | grep -v "health check"
```

### Container-Specific Logs

```bash
# Get container names
docker compose ps --format "table {{.Names}}"

# Direct container logs
docker logs ghostfolio-ghostfolio-1
docker logs ghostfolio-postgres-1
docker logs ghostfolio-redis-1

# Follow container logs
docker logs -f ghostfolio-ghostfolio-1

# Show logs with details
docker logs --details ghostfolio-ghostfolio-1
```

## 🖥️ Application Logs

### Ghostfolio Application Logs

```bash
# Access application container
docker compose exec ghostfolio sh

# Check if application creates log files
ls -la /app/logs/
ls -la /app/*.log
ls -la /var/log/

# Check application stdout/stderr
docker compose logs ghostfolio | grep -E "(stdout|stderr)"

# Node.js application logs
docker compose logs ghostfolio | grep -E "(console\.log|console\.error)"

# Check for crash logs
docker compose logs ghostfolio | grep -i "crash\|segfault\|fatal"
```

### Application Debug Mode

```bash
# Enable debug mode in environment
echo "DEBUG=*" >> .env
docker compose restart ghostfolio

# Enable specific debug namespaces
echo "DEBUG=ghostfolio:*" >> .env
docker compose restart ghostfolio

# Check Node.js debug output
docker compose logs ghostfolio | grep -i debug

# Monitor application startup
docker compose logs -f ghostfolio | grep -E "(starting|listening|ready)"
```

### Performance Logging

```bash
# Monitor application performance
docker compose exec ghostfolio top
docker compose exec ghostfolio ps aux

# Check memory usage
docker compose exec ghostfolio cat /proc/meminfo
docker compose exec ghostfolio free -h

# Monitor application process
docker compose exec ghostfolio cat /proc/1/status
docker stats ghostfolio-ghostfolio-1
```

## 🗄️ Database Logs

### PostgreSQL Logs

```bash
# Access PostgreSQL container
docker compose exec postgres bash

# Find PostgreSQL log directory
ls -la /var/lib/postgresql/data/log/
ls -la /var/log/postgresql/

# View current PostgreSQL logs
tail -f /var/lib/postgresql/data/log/postgresql-*.log

# Search for errors in PostgreSQL logs
grep -i error /var/lib/postgresql/data/log/postgresql-*.log

# Search for slow queries
grep -i "slow" /var/lib/postgresql/data/log/postgresql-*.log

# View connection logs
grep -i "connection" /var/lib/postgresql/data/log/postgresql-*.log
```

### Database Query Logging

```bash
# Enable query logging (temporary)
docker compose exec postgres psql -U ghostfolio -d ghostfolio -c "ALTER SYSTEM SET log_statement = 'all';"
docker compose exec postgres psql -U ghostfolio -d ghostfolio -c "SELECT pg_reload_conf();"

# Enable slow query logging
docker compose exec postgres psql -U ghostfolio -d ghostfolio -c "ALTER SYSTEM SET log_min_duration_statement = 1000;"  # Log queries > 1s

# Check current logging configuration
docker compose exec postgres psql -U ghostfolio -d ghostfolio -c "SHOW log_statement;"
docker compose exec postgres psql -U ghostfolio -d ghostfolio -c "SHOW log_min_duration_statement;"

# View active connections
docker compose exec postgres psql -U ghostfolio -d ghostfolio -c "SELECT * FROM pg_stat_activity;"
```

### Database Error Analysis

```bash
# Check for constraint violations
docker compose logs postgres | grep -i "constraint"

# Check for connection issues
docker compose logs postgres | grep -i "connection refused\|could not connect"

# Check for authentication issues
docker compose logs postgres | grep -i "authentication\|password"

# Check for deadlocks
docker compose logs postgres | grep -i "deadlock"

# Database startup issues
docker compose logs postgres | grep -i "fatal\|panic\|failed"
```

## 🖲️ System Logs

### Host System Logs

```bash
# System journal logs
journalctl -f

# Docker daemon logs
journalctl -u docker -f

# Container-specific system logs
journalctl CONTAINER_NAME=ghostfolio-ghostfolio-1

# Check for Out of Memory (OOM) kills
dmesg | grep -i "killed process\|out of memory"
journalctl | grep -i "oom\|memory"

# System resource logs
sar -r 1 5  # Memory usage
sar -u 1 5  # CPU usage
iostat -x 1 5  # I/O usage
```

### Docker System Logs

```bash
# Docker daemon events
docker events

# Filter events by container
docker events --filter container=ghostfolio-ghostfolio-1

# Filter events by type
docker events --filter type=container
docker events --filter event=start
docker events --filter event=die

# Docker system information
docker system df
docker system info

# Check Docker daemon logs
sudo journalctl -u docker.service -f
```

## 🔍 Log Analysis Tools

### Using grep for Pattern Matching

```bash
# Multiple pattern search
docker compose logs ghostfolio | grep -E "(error|exception|fail|timeout)"

# Case-insensitive search
docker compose logs ghostfolio | grep -i "database connection"

# Inverted match (exclude patterns)
docker compose logs ghostfolio | grep -v "health check\|ping"

# Show line numbers
docker compose logs ghostfolio | grep -n "error"

# Count occurrences
docker compose logs ghostfolio | grep -c "error"
docker compose logs ghostfolio | grep -c "success"

# Search with context
docker compose logs ghostfolio | grep -A 3 -B 3 "error"
```

### Using awk for Log Processing

```bash
# Extract timestamps
docker compose logs -t ghostfolio | awk '{print $1, $2}'

# Count log levels
docker compose logs ghostfolio | awk '/ERROR/ {errors++} /WARN/ {warns++} /INFO/ {infos++} END {print "Errors:", errors, "Warnings:", warns, "Info:", infos}'

# Filter by time range
docker compose logs -t ghostfolio | awk '$2 > "10:00:00" && $2 < "11:00:00"'

# Extract specific fields
docker compose logs ghostfolio | awk -F'|' '{print $2}'  # Assuming pipe-delimited logs
```

### Using jq for JSON Logs

```bash
# If logs are in JSON format
docker compose logs ghostfolio | jq '.level, .message'

# Filter JSON logs by level
docker compose logs ghostfolio | jq 'select(.level == "error")'

# Extract specific JSON fields
docker compose logs ghostfolio | jq -r '.timestamp + " " + .level + " " + .message'

# Count JSON log levels
docker compose logs ghostfolio | jq -r '.level' | sort | uniq -c
```

## 📈 Real-time Monitoring

### Multi-tail Log Monitoring

```bash
# Install multitail (if not available)
sudo apt-get install multitail

# Monitor multiple services simultaneously
multitail \
  -l "docker compose logs -f ghostfolio" \
  -l "docker compose logs -f postgres" \
  -l "docker compose logs -f redis"

# Monitor with custom labels
multitail \
  -t "Ghostfolio" -l "docker compose logs -f ghostfolio" \
  -t "Database" -l "docker compose logs -f postgres"
```

### Using tmux for Multiple Log Windows

```bash
# Start tmux session
tmux new-session -d -s ghostfolio-logs

# Create windows for each service
tmux new-window -t ghostfolio-logs -n 'app' 'docker compose logs -f ghostfolio'
tmux new-window -t ghostfolio-logs -n 'db' 'docker compose logs -f postgres'
tmux new-window -t ghostfolio-logs -n 'redis' 'docker compose logs -f redis'

# Attach to session
tmux attach-session -t ghostfolio-logs
```

### Log Aggregation with lnav

```bash
# Install lnav (log file navigator)
sudo apt-get install lnav

# Save logs to files
docker compose logs ghostfolio > ghostfolio.log
docker compose logs postgres > postgres.log
docker compose logs redis > redis.log

# View with lnav
lnav ghostfolio.log postgres.log redis.log

# Live monitoring with lnav
docker compose logs -f ghostfolio | lnav
```

## 🔄 Log Rotation & Management

### Configure Log Rotation

```bash
# Add to docker-compose.yml for each service
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"

# Alternative: Configure in /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

### Manual Log Cleanup

```bash
# Find large log files
docker system df
du -h /var/lib/docker/containers/*/*-json.log | sort -h

# Truncate logs (careful!)
sudo truncate -s 0 /var/lib/docker/containers/*/*-json.log

# Remove old container logs
docker container prune

# Clean up Docker system
docker system prune
```

### Automated Log Management

```bash
# Create log cleanup script
cat << 'EOF' > cleanup-logs.sh
#!/bin/bash

# Clean Docker logs older than 7 days
find /var/lib/docker/containers/ -name "*.log" -mtime +7 -delete

# Clean up old container logs
docker container prune -f

# Clean up unused images
docker image prune -f

# Clean up unused volumes
docker volume prune -f

echo "Log cleanup completed"
EOF

chmod +x cleanup-logs.sh

# Add to crontab for weekly cleanup
echo "0 2 * * 0 /path/to/cleanup-logs.sh" | crontab -
```

## 🔧 Debugging Workflows

### Application Not Starting

```bash
# 1. Check service status
docker compose ps

# 2. Check service logs
docker compose logs ghostfolio

# 3. Check for common issues
docker compose logs ghostfolio | grep -E "(error|exception|fail|timeout)"

# 4. Verify configuration
docker compose config

# 5. Check dependencies
docker compose logs postgres
docker compose logs redis

# 6. Test connectivity
docker compose exec ghostfolio ping postgres
docker compose exec ghostfolio ping redis
```

### Database Connection Issues

```bash
# 1. Check database logs
docker compose logs postgres | grep -E "(error|connection|authentication)"

# 2. Test database connection
docker compose exec ghostfolio pg_isready -h postgres -p 5432

# 3. Verify credentials
docker compose exec postgres psql -U ghostfolio -d ghostfolio -c "\l"

# 4. Check network connectivity
docker compose exec ghostfolio nslookup postgres
docker compose exec ghostfolio telnet postgres 5432

# 5. Verify environment variables
docker compose exec ghostfolio env | grep -i database
```

### Performance Issues

```bash
# 1. Monitor resource usage
docker stats

# 2. Check for memory leaks
docker compose exec ghostfolio cat /proc/1/status | grep VmRSS

# 3. Check database performance
docker compose exec postgres psql -U ghostfolio -d ghostfolio -c "SELECT * FROM pg_stat_activity;"

# 4. Monitor slow queries
docker compose logs postgres | grep -i "slow\|duration"

# 5. Check Redis performance
docker compose exec redis redis-cli info stats
docker compose exec redis redis-cli slowlog get 10
```

### Container Health Issues

```bash
# 1. Check container health status
docker compose ps --filter "health=unhealthy"

# 2. Inspect health check logs
docker inspect ghostfolio-ghostfolio-1 | jq '.[].State.Health.Log'

# 3. Manually run health check
docker compose exec ghostfolio curl -f http://localhost:3333/api/v1/health

# 4. Check container processes
docker compose exec ghostfolio ps aux

# 5. Monitor container resources
docker stats ghostfolio-ghostfolio-1
```

## 📝 Log Analysis Scripts

### Error Summary Script

```bash
cat << 'EOF' > analyze-logs.sh
#!/bin/bash

echo "=== Ghostfolio Log Analysis ==="
echo "Date: $(date)"
echo

echo "Error Summary:"
docker compose logs ghostfolio | grep -i error | wc -l
echo "  - Total errors: $(docker compose logs ghostfolio | grep -i error | wc -l)"
echo "  - Database errors: $(docker compose logs ghostfolio | grep -i "database.*error" | wc -l)"
echo "  - Connection errors: $(docker compose logs ghostfolio | grep -i "connection.*error" | wc -l)"

echo
echo "Recent Errors (last 10):"
docker compose logs ghostfolio | grep -i error | tail -10

echo
echo "Service Status:"
docker compose ps

echo
echo "Resource Usage:"
docker stats --no-stream
EOF

chmod +x analyze-logs.sh
```

### Daily Log Report

```bash
cat << 'EOF' > daily-report.sh
#!/bin/bash

DATE=$(date +%Y-%m-%d)
REPORT_FILE="ghostfolio-report-$DATE.txt"

{
  echo "Ghostfolio Daily Report - $DATE"
  echo "========================================"
  echo
  
  echo "Service Status:"
  docker compose ps
  echo
  
  echo "Error Count (last 24h):"
  echo "  Ghostfolio: $(docker compose logs --since 24h ghostfolio | grep -i error | wc -l)"
  echo "  PostgreSQL: $(docker compose logs --since 24h postgres | grep -i error | wc -l)"
  echo "  Redis: $(docker compose logs --since 24h redis | grep -i error | wc -l)"
  echo
  
  echo "Performance Summary:"
  docker stats --no-stream
  echo
  
  echo "Database Connections:"
  docker compose exec postgres psql -U ghostfolio -d ghostfolio -c "SELECT count(*) as active_connections FROM pg_stat_activity WHERE state = 'active';"
  echo
  
  echo "Redis Memory Usage:"
  docker compose exec redis redis-cli info memory | grep used_memory_human
  
} > "$REPORT_FILE"

echo "Report generated: $REPORT_FILE"
EOF

chmod +x daily-report.sh
```

## 📝 Quick Reference

| Command | Description |
|---------|-------------|
| `docker compose logs -f <service>` | Follow service logs |
| `docker compose logs --tail 50 <service>` | Show last 50 lines |
| `docker compose logs --since "1h" <service>` | Show logs from last hour |
| `docker compose logs <service> \| grep error` | Filter for errors |
| `docker stats` | Show container resource usage |
| `journalctl -u docker -f` | Follow Docker daemon logs |
| `docker events` | Monitor Docker events |
| `docker system df` | Show Docker disk usage |

---

💡 **Pro Tip**: Set up log aggregation and alerting for production environments. Consider tools like ELK Stack, Grafana, or simple scripts that notify you of critical errors.
