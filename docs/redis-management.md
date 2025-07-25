# Redis Configuration & Management

Complete guide to managing Redis in your Ghostfolio deployment.

## 📋 Table of Contents

- [Container Access](#container-access)
- [Redis File Structure](#redis-file-structure)
- [Configuration Management](#configuration-management)
- [Data Management](#data-management)
- [Performance Tuning](#performance-tuning)
- [Monitoring & Debugging](#monitoring--debugging)
- [Backup & Recovery](#backup--recovery)
- [Security Configuration](#security-configuration)

## 🔐 Container Access

### Basic Access

```bash
# Access Redis container shell
docker compose exec redis sh

# Access Redis CLI directly
docker compose exec redis redis-cli

# Access Redis CLI with authentication (if password set)
docker compose exec redis redis-cli -a your_redis_password

# Access Redis CLI from application container
docker compose exec ghostfolio redis-cli -h redis -p 6379
```

### Redis CLI Commands

```bash
# Connect to Redis and test connection
docker compose exec redis redis-cli ping
# Expected response: PONG

# Get Redis server information
docker compose exec redis redis-cli info

# Monitor Redis commands in real-time
docker compose exec redis redis-cli monitor

# Access with database selection
docker compose exec redis redis-cli -n 0  # Database 0 (default)
```

## 📁 Redis File Structure

### Container File System

```bash
# Access Redis container
docker compose exec redis sh

# Redis installation directory
ls -la /usr/local/bin/redis-*

# Redis configuration directory
ls -la /etc/redis/

# Redis data directory (if persistence enabled)
ls -la /data/

# Redis log files
ls -la /var/log/redis/
```

### Configuration Files

```bash
# View Redis configuration
docker compose exec redis cat /etc/redis/redis.conf

# Check for custom configuration
docker compose exec redis cat /usr/local/etc/redis/redis.conf

# View running configuration
docker compose exec redis redis-cli config get "*"

# Check specific configuration
docker compose exec redis redis-cli config get "save"
docker compose exec redis redis-cli config get "maxmemory"
```

### Data Persistence Files

```bash
# Check RDB dump files (if enabled)
docker compose exec redis ls -la /data/*.rdb

# Check AOF files (if enabled)
docker compose exec redis ls -la /data/*.aof

# View data directory permissions
docker compose exec redis ls -la /data/
```

## ⚙️ Configuration Management

### Runtime Configuration

```bash
# Get current configuration
docker compose exec redis redis-cli config get "*" | grep -A1 "maxmemory"

# Set configuration at runtime
docker compose exec redis redis-cli config set maxmemory 256mb
docker compose exec redis redis-cli config set maxmemory-policy allkeys-lru

# Save configuration to file
docker compose exec redis redis-cli config rewrite

# Reset specific configuration
docker compose exec redis redis-cli config set save ""
```

### Memory Configuration

```bash
# Check memory usage
docker compose exec redis redis-cli info memory

# Set memory limit
docker compose exec redis redis-cli config set maxmemory 512mb

# Configure eviction policy
docker compose exec redis redis-cli config set maxmemory-policy volatile-lru

# Available eviction policies:
# - noeviction: No eviction (returns error when memory limit reached)
# - allkeys-lru: Remove least recently used keys
# - volatile-lru: Remove LRU keys with expire set
# - allkeys-random: Remove random keys
# - volatile-random: Remove random keys with expire set
# - volatile-ttl: Remove keys with shortest TTL
```

### Persistence Configuration

```bash
# Configure RDB snapshots
docker compose exec redis redis-cli config set save "900 1 300 10 60 10000"

# Disable RDB snapshots
docker compose exec redis redis-cli config set save ""

# Enable AOF (Append Only File)
docker compose exec redis redis-cli config set appendonly yes

# Configure AOF sync policy
docker compose exec redis redis-cli config set appendfsync everysec
```

## 💾 Data Management

### Database Operations

```bash
# List all keys
docker compose exec redis redis-cli keys "*"

# Count total keys
docker compose exec redis redis-cli dbsize

# Select database (Redis has 16 databases by default: 0-15)
docker compose exec redis redis-cli select 0

# Get information about specific database
docker compose exec redis redis-cli info keyspace

# Flush specific database
docker compose exec redis redis-cli flushdb

# Flush all databases (BE CAREFUL!)
docker compose exec redis redis-cli flushall
```

### Key Management

```bash
# Get key type
docker compose exec redis redis-cli type "your_key"

# Get key TTL (time to live)
docker compose exec redis redis-cli ttl "your_key"

# Set key expiration
docker compose exec redis redis-cli expire "your_key" 3600  # 1 hour

# Remove key expiration
docker compose exec redis redis-cli persist "your_key"

# Get key size
docker compose exec redis redis-cli memory usage "your_key"

# Scan keys with pattern
docker compose exec redis redis-cli scan 0 match "session:*" count 100
```

### Ghostfolio-Specific Data

```bash
# Check session data (common Ghostfolio keys)
docker compose exec redis redis-cli keys "sess:*"

# Check cache data
docker compose exec redis redis-cli keys "cache:*"

# View Ghostfolio session
docker compose exec redis redis-cli get "sess:your_session_id"

# Check user cache data
docker compose exec redis redis-cli keys "user:*"

# Monitor Ghostfolio operations
docker compose exec redis redis-cli monitor | grep -i ghostfolio
```

## 🚀 Performance Tuning

### Memory Optimization

```bash
# Check memory usage breakdown
docker compose exec redis redis-cli info memory

# Key memory usage statistics
docker compose exec redis redis-cli memory stats

# Sample key memory usage
docker compose exec redis redis-cli memory usage "your_key" samples 5

# Configure memory-efficient data structures
docker compose exec redis redis-cli config set hash-max-ziplist-entries 512
docker compose exec redis redis-cli config set hash-max-ziplist-value 64
```

### Connection Optimization

```bash
# Check connection statistics
docker compose exec redis redis-cli info clients

# Set maximum connections
docker compose exec redis redis-cli config set maxclients 1000

# Connection timeout settings
docker compose exec redis redis-cli config set timeout 300

# TCP keepalive
docker compose exec redis redis-cli config set tcp-keepalive 60
```

### Performance Monitoring

```bash
# Get slow queries log
docker compose exec redis redis-cli slowlog get 10

# Configure slow log
docker compose exec redis redis-cli config set slowlog-log-slower-than 10000  # 10ms
docker compose exec redis redis-cli config set slowlog-max-len 100

# Check latency
docker compose exec redis redis-cli latency latest

# Enable latency monitoring
docker compose exec redis redis-cli config set latency-monitor-threshold 100
```

## 📊 Monitoring & Debugging

### Real-time Monitoring

```bash
# Monitor Redis operations
docker compose exec redis redis-cli monitor

# Monitor specific operations
docker compose exec redis redis-cli monitor | grep -E "(GET|SET|DEL)"

# Statistics monitoring
docker compose exec redis redis-cli --stat

# Monitor with interval
docker compose exec redis redis-cli --stat -i 1  # Every 1 second

# Latency monitoring
docker compose exec redis redis-cli --latency
```

### Server Information

```bash
# Complete server information
docker compose exec redis redis-cli info

# Specific information sections
docker compose exec redis redis-cli info server
docker compose exec redis redis-cli info memory
docker compose exec redis redis-cli info clients
docker compose exec redis redis-cli info persistence
docker compose exec redis redis-cli info stats
docker compose exec redis redis-cli info replication

# Client list
docker compose exec redis redis-cli client list

# Last save time
docker compose exec redis redis-cli lastsave
```

### Debugging Tools

```bash
# Debug object information
docker compose exec redis redis-cli debug object "your_key"

# Check Redis configuration issues
docker compose exec redis redis-cli config get "*" | grep -i error

# Validate RDB file
docker compose exec redis redis-cli debug reload

# Memory debugging
docker compose exec redis redis-cli memory doctor

# Network diagnostics from app container
docker compose exec ghostfolio telnet redis 6379
```

## 💾 Backup & Recovery

### Manual Backup

```bash
# Force background save
docker compose exec redis redis-cli bgsave

# Check if background save is in progress
docker compose exec redis redis-cli lastsave

# Manual save (blocks Redis)
docker compose exec redis redis-cli save

# Copy RDB file from container
docker cp ghostfolio-redis-1:/data/dump.rdb ./redis-backup-$(date +%Y%m%d_%H%M%S).rdb
```

### Automated Backup

```bash
# Create backup script
cat << 'EOF' > backup-redis.sh
#!/bin/bash
BACKUP_DIR="/path/to/backups"
DATE=$(date +%Y%m%d_%H%M%S)

# Trigger background save
docker compose exec redis redis-cli bgsave

# Wait for save to complete
sleep 5

# Copy backup file
docker cp ghostfolio-redis-1:/data/dump.rdb "$BACKUP_DIR/redis-$DATE.rdb"

echo "Redis backup completed: redis-$DATE.rdb"
EOF

chmod +x backup-redis.sh
```

### Recovery

```bash
# Stop Redis service
docker compose stop redis

# Replace RDB file
docker cp ./redis-backup.rdb ghostfolio-redis-1:/data/dump.rdb

# Fix permissions
docker compose exec --user root redis chown redis:redis /data/dump.rdb

# Start Redis service
docker compose start redis

# Verify data recovery
docker compose exec redis redis-cli dbsize
```

## 🔒 Security Configuration

### Authentication

```bash
# Set Redis password
docker compose exec redis redis-cli config set requirepass "your_secure_password"

# Test authentication
docker compose exec redis redis-cli -a "your_secure_password" ping

# Remove password
docker compose exec redis redis-cli -a "your_secure_password" config set requirepass ""
```

### Access Control

```bash
# Disable dangerous commands (in production)
docker compose exec redis redis-cli config set rename-command FLUSHDB ""
docker compose exec redis redis-cli config set rename-command FLUSHALL ""
docker compose exec redis redis-cli config set rename-command DEBUG ""

# Check current command renaming
docker compose exec redis redis-cli config get "*command*"

# Protected mode (enabled by default)
docker compose exec redis redis-cli config get protected-mode
```

### Network Security

```bash
# Bind to specific interfaces
docker compose exec redis redis-cli config set bind "127.0.0.1 ::1"

# Check listening addresses
docker compose exec redis netstat -tuln | grep 6379

# Set client timeout
docker compose exec redis redis-cli config set timeout 300
```

## 🔧 Advanced Configuration

### Custom Redis Configuration

Create a custom Redis configuration file:

```bash
# Create custom redis.conf
cat << 'EOF' > ./config/redis.conf
# Redis configuration for Ghostfolio

# Network
bind 0.0.0.0
port 6379
timeout 300
tcp-keepalive 60

# Memory
maxmemory 512mb
maxmemory-policy allkeys-lru

# Persistence
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb

# Logging
loglevel notice
logfile "/var/log/redis/redis.log"

# Security
protected-mode yes
# requirepass your_password_here

# Advanced
tcp-backlog 511
databases 16
EOF
```

### Update docker-compose.yml to use custom config:

```yaml
redis:
  image: redis:7-alpine
  container_name: ${PROJECT_NAME}-redis
  volumes:
    - ./config/redis.conf:/usr/local/etc/redis/redis.conf
    - ${DATA_BASE_PATH}/data/cache/redis:/data
  command: redis-server /usr/local/etc/redis/redis.conf
```

## 📝 Quick Reference

| Command | Description |
|---------|-------------|
| `redis-cli ping` | Test Redis connection |
| `redis-cli info` | Get server information |
| `redis-cli monitor` | Monitor Redis operations |
| `redis-cli keys "*"` | List all keys |
| `redis-cli dbsize` | Count keys in database |
| `redis-cli flushdb` | Clear current database |
| `redis-cli config get "*"` | Show all configuration |
| `redis-cli bgsave` | Background save |
| `redis-cli client list` | Show connected clients |
| `redis-cli slowlog get 10` | Show slow queries |

## 🚨 Troubleshooting

### Common Issues

```bash
# Redis won't start - check logs
docker compose logs redis

# Connection refused - check if Redis is running
docker compose exec ghostfolio redis-cli -h redis ping

# Memory issues - check memory usage
docker compose exec redis redis-cli info memory

# Performance issues - check slow log
docker compose exec redis redis-cli slowlog get

# Data persistence issues - check RDB file
docker compose exec redis ls -la /data/dump.rdb
```

### Performance Issues

```bash
# Check for blocking operations
docker compose exec redis redis-cli client list | grep blocked

# Monitor command latency
docker compose exec redis redis-cli --latency-history -i 1

# Check memory fragmentation
docker compose exec redis redis-cli info memory | grep fragmentation

# Analyze memory usage
docker compose exec redis redis-cli memory stats
```

---

💡 **Pro Tip**: For production environments, always configure password authentication and disable dangerous commands!
