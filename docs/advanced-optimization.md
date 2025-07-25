# Advanced Server Optimization & Monitoring

Advanced techniques for optimizing performance, monitoring, and maintaining your Ghostfolio deployment in production environments.

## 📋 Table of Contents

- [Performance Optimization](#performance-optimization)
- [Resource Monitoring](#resource-monitoring)
- [Network Optimization](#network-optimization)
- [Storage Optimization](#storage-optimization)
- [Security Hardening](#security-hardening)
- [Automated Health Checks](#automated-health-checks)
- [Load Balancing & Scaling](#load-balancing--scaling)
- [Disaster Recovery](#disaster-recovery)

## 🚀 Performance Optimization

### Docker Performance Tuning

```bash
# Optimize Docker daemon configuration
sudo cat << 'EOF' > /etc/docker/daemon.json
{
  "storage-driver": "overlay2",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "default-ulimits": {
    "nofile": {
      "Hard": 64000,
      "Name": "nofile",
      "Soft": 32000
    }
  },
  "live-restore": true,
  "userland-proxy": false,
  "experimental": false,
  "metrics-addr": "127.0.0.1:9323",
  "dns": ["8.8.8.8", "1.1.1.1"]
}
EOF

sudo systemctl restart docker
```

### Container Resource Optimization

```yaml
# Add to docker-compose.yml
services:
  ghostfolio:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
        reservations:
          cpus: '0.5'
          memory: 512M
      restart_policy:
        condition: unless-stopped
        delay: 10s
        max_attempts: 3
        window: 60s
    
  postgres:
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          cpus: '0.25'
          memory: 256M
    environment:
      # PostgreSQL performance tuning
      POSTGRES_INITDB_ARGS: "--auth-host=md5 --auth-local=peer"
    command: >
      postgres
      -c shared_buffers=256MB
      -c effective_cache_size=1GB
      -c maintenance_work_mem=64MB
      -c checkpoint_completion_target=0.9
      -c wal_buffers=16MB
      -c default_statistics_target=100
      -c random_page_cost=1.1
      -c effective_io_concurrency=200
      -c work_mem=4MB
      -c max_connections=200
      -c log_statement=none
      -c log_duration=off
      -c log_lock_waits=on
      -c log_checkpoints=on
```

### Application Performance Tuning

```bash
# Node.js performance optimization in .env
NODE_ENV=production
NODE_OPTIONS="--max-old-space-size=1024 --optimize-for-size"
UV_THREADPOOL_SIZE=4

# Enable compression and caching
COMPRESSION=true
CACHE_TTL=3600

# Database connection optimization
DB_POOL_MIN=2
DB_POOL_MAX=10
DB_POOL_IDLE=10000

# Redis optimization
REDIS_MAX_MEMORY=256mb
REDIS_MAX_MEMORY_POLICY=allkeys-lru
```

## 📊 Resource Monitoring

### System Monitoring Setup

```bash
# Install monitoring tools
sudo apt update && sudo apt install \
    htop iotop nethogs sysstat \
    prometheus-node-exporter \
    collectd collectd-utils

# Configure system monitoring
cat << 'EOF' > monitor-system.sh
#!/bin/bash

LOG_FILE="/var/log/ghostfolio-monitor.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

{
    echo "[$DATE] System Monitor Report"
    echo "=============================="
    
    # CPU Usage
    echo "CPU Usage:"
    mpstat 1 1 | tail -1
    
    # Memory Usage
    echo -e "\nMemory Usage:"
    free -h
    
    # Disk Usage
    echo -e "\nDisk Usage:"
    df -h | grep -E "(/$|/opt|/var)"
    
    # Docker Stats
    echo -e "\nDocker Container Stats:"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
    
    # Network Connections
    echo -e "\nNetwork Connections:"
    ss -tuln | grep -E ":8061|:5432|:6379"
    
    # Load Average
    echo -e "\nLoad Average:"
    uptime
    
    echo -e "\n================================\n"
} >> "$LOG_FILE"

# Rotate log file
if [ -f "$LOG_FILE" ] && [ $(stat -c%s "$LOG_FILE") -gt 10485760 ]; then  # 10MB
    sudo mv "$LOG_FILE" "${LOG_FILE}.$(date +%Y%m%d)"
    sudo gzip "${LOG_FILE}.$(date +%Y%m%d)"
fi
EOF

chmod +x monitor-system.sh

# Add to crontab for every 5 minutes
echo "*/5 * * * * /path/to/ghostfolio-docker/monitor-system.sh" | crontab -
```

### Container-Specific Monitoring

```bash
# Detailed container monitoring script
cat << 'EOF' > monitor-containers.sh
#!/bin/bash

echo "=== Ghostfolio Container Monitoring ==="
echo "Date: $(date)"
echo

# Container health status
echo "Container Health:"
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

echo -e "\nContainer Resource Usage:"
docker stats --no-stream

echo -e "\nContainer Processes:"
echo "--- Ghostfolio ---"
docker compose exec ghostfolio ps aux | head -10

echo -e "\n--- PostgreSQL ---"
docker compose exec postgres ps aux | head -10

echo -e "\n--- Redis ---"
docker compose exec redis ps aux | head -10

# Memory details
echo -e "\nDetailed Memory Usage:"
for container in ghostfolio postgres redis; do
    if docker compose ps | grep -q $container; then
        echo "--- $container ---"
        docker compose exec $container cat /proc/meminfo | grep -E "(MemTotal|MemFree|MemAvailable|Buffers|Cached)"
    fi
done

# Network statistics
echo -e "\nNetwork Statistics:"
docker compose exec ghostfolio cat /proc/net/dev | grep eth0 || echo "Network interface not found"

# Disk I/O
echo -e "\nDisk I/O Statistics:"
for container in ghostfolio postgres redis; do
    if docker compose ps | grep -q $container; then
        echo "--- $container ---"
        docker compose exec $container cat /proc/diskstats | head -5
    fi
done
EOF

chmod +x monitor-containers.sh
```

### Database Performance Monitoring

```bash
# PostgreSQL monitoring queries
cat << 'EOF' > monitor-database.sh
#!/bin/bash

echo "=== PostgreSQL Performance Monitor ==="
echo "Date: $(date)"
echo

# Connection stats
echo "Database Connections:"
docker compose exec postgres psql -U ghostfolio -d ghostfolio -c "
SELECT state, count(*) 
FROM pg_stat_activity 
WHERE state IS NOT NULL 
GROUP BY state;"

# Query performance
echo -e "\nSlow Queries (last hour):"
docker compose exec postgres psql -U ghostfolio -d ghostfolio -c "
SELECT query, calls, total_time, mean_time 
FROM pg_stat_statements 
WHERE total_time > 1000 
ORDER BY total_time DESC 
LIMIT 10;" 2>/dev/null || echo "pg_stat_statements not enabled"

# Database size
echo -e "\nDatabase Size:"
docker compose exec postgres psql -U ghostfolio -d ghostfolio -c "
SELECT pg_size_pretty(pg_database_size('ghostfolio')) as database_size;"

# Table sizes
echo -e "\nLargest Tables:"
docker compose exec postgres psql -U ghostfolio -d ghostfolio -c "
SELECT schemaname, tablename, 
       pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC 
LIMIT 10;"

# Index usage
echo -e "\nIndex Usage:"
docker compose exec postgres psql -U ghostfolio -d ghostfolio -c "
SELECT schemaname, tablename, indexname, idx_scan 
FROM pg_stat_user_indexes 
ORDER BY idx_scan DESC 
LIMIT 10;"

# Buffer cache hit ratio
echo -e "\nBuffer Cache Hit Ratio:"
docker compose exec postgres psql -U ghostfolio -d ghostfolio -c "
SELECT round(
  100.0 * sum(blks_hit) / (sum(blks_hit) + sum(blks_read)), 2
) as cache_hit_ratio 
FROM pg_stat_database;"
EOF

chmod +x monitor-database.sh
```

## 🌐 Network Optimization

### Nginx Reverse Proxy Optimization

```nginx
# /etc/nginx/sites-available/ghostfolio-optimized
upstream ghostfolio_backend {
    least_conn;
    server 127.0.0.1:8061 max_fails=3 fail_timeout=30s;
    keepalive 32;
}

# Rate limiting
limit_req_zone $binary_remote_addr zone=ghostfolio:10m rate=10r/s;
limit_conn_zone $binary_remote_addr zone=addr:10m;

server {
    listen 443 ssl http2;
    server_name your-domain.com;
    
    # SSL optimization
    ssl_certificate /etc/ssl/certs/ghostfolio.crt;
    ssl_certificate_key /etc/ssl/private/ghostfolio.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    # Rate limiting
    limit_req zone=ghostfolio burst=20 nodelay;
    limit_conn addr 10;
    
    # Compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
    
    # Browser caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Main proxy
    location / {
        proxy_pass http://ghostfolio_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Buffer settings
        proxy_buffering on;
        proxy_buffer_size 128k;
        proxy_buffers 4 256k;
        proxy_busy_buffers_size 256k;
    }
    
    # Health check endpoint
    location /health {
        access_log off;
        proxy_pass http://ghostfolio_backend/api/v1/health;
    }
}
```

### Container Network Optimization

```yaml
# docker-compose.yml network optimization
networks:
  ghostfolio-net:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
    driver_opts:
      com.docker.network.bridge.name: "ghostfolio-br"
      com.docker.network.driver.mtu: 1500

services:
  ghostfolio:
    networks:
      ghostfolio-net:
        ipv4_address: 172.20.0.10
    sysctls:
      - net.core.somaxconn=65535
      - net.ipv4.tcp_tw_reuse=1
      - net.ipv4.tcp_fin_timeout=30
    
  postgres:
    networks:
      ghostfolio-net:
        ipv4_address: 172.20.0.20
        
  redis:
    networks:
      ghostfolio-net:
        ipv4_address: 172.20.0.30
```

## 💾 Storage Optimization

### Disk I/O Optimization

```bash
# Optimize disk scheduler for SSDs
echo mq-deadline | sudo tee /sys/block/sda/queue/scheduler

# Mount optimization for database volumes
sudo cat << 'EOF' >> /etc/fstab
# Ghostfolio data partition optimization
/dev/disk/by-label/ghostfolio-data /opt/ghostfolio ext4 defaults,noatime,nodiratime,barrier=0 0 2
EOF

# Docker volume optimization
cat << 'EOF' > docker-compose.override.yml
version: '3.8'

services:
  postgres:
    volumes:
      - postgres_data:/var/lib/postgresql/data:Z
      - /dev/shm:/dev/shm  # Use shared memory for PostgreSQL
    shm_size: 256mb
    
volumes:
  postgres_data:
    driver: local
    driver_opts:
      type: none
      o: bind,noatime,nodiratime
      device: /opt/ghostfolio/data/db/postgre
EOF
```

### Database Storage Optimization

```bash
# PostgreSQL storage optimization
cat << 'EOF' > optimize-postgres.sql
-- Optimize PostgreSQL for performance
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET effective_cache_size = '1GB';
ALTER SYSTEM SET maintenance_work_mem = '64MB';
ALTER SYSTEM SET checkpoint_completion_target = 0.9;
ALTER SYSTEM SET wal_buffers = '16MB';
ALTER SYSTEM SET default_statistics_target = 100;
ALTER SYSTEM SET random_page_cost = 1.1;
ALTER SYSTEM SET effective_io_concurrency = 200;
ALTER SYSTEM SET work_mem = '4MB';
ALTER SYSTEM SET max_connections = 200;

-- Reload configuration
SELECT pg_reload_conf();

-- Create indexes for better performance
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_activities_user_id ON "Activity" (user_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_user_id ON "Order" (user_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_date ON "Order" (date);

-- Analyze tables
ANALYZE;
EOF

# Apply optimizations
docker compose exec postgres psql -U ghostfolio -d ghostfolio -f /tmp/optimize-postgres.sql
```

### Log Rotation and Cleanup

```bash
# Automated cleanup script
cat << 'EOF' > cleanup-storage.sh
#!/bin/bash

echo "=== Storage Cleanup Script ==="
echo "Date: $(date)"
echo

# Docker cleanup
echo "Cleaning Docker resources..."
docker system prune -f
docker volume prune -f
docker image prune -f

# Log cleanup
echo "Cleaning application logs..."
find /opt/ghostfolio/logs -name "*.log" -mtime +7 -delete
find /var/log -name "*ghostfolio*" -mtime +30 -delete

# PostgreSQL log cleanup
echo "Cleaning PostgreSQL logs..."
docker compose exec postgres find /var/lib/postgresql/data/log -name "*.log" -mtime +7 -delete 2>/dev/null || true

# Backup cleanup (keep last 10 backups)
echo "Cleaning old backups..."
find /opt/ghostfolio/backups -name "*.tar.gz" -type f | sort -r | tail -n +11 | xargs rm -f

# Check disk usage after cleanup
echo "Disk usage after cleanup:"
df -h | grep -E "(/$|/opt|/var)"

echo "Cleanup completed"
EOF

chmod +x cleanup-storage.sh

# Schedule weekly cleanup
echo "0 3 * * 0 /path/to/ghostfolio-docker/cleanup-storage.sh >> /var/log/cleanup.log 2>&1" | crontab -
```

## 🔒 Security Hardening

### Container Security

```yaml
# Security-hardened docker-compose.yml
services:
  ghostfolio:
    read_only: true
    tmpfs:
      - /tmp:noexec,nosuid,size=100m
      - /var/run:noexec,nosuid,size=50m
    security_opt:
      - no-new-privileges:true
      - apparmor:docker-ghostfolio
    cap_drop:
      - ALL
    cap_add:
      - CHOWN
      - DAC_OVERRIDE
      - SETGID
      - SETUID
    user: "1000:1000"
    
  postgres:
    read_only: true
    tmpfs:
      - /tmp:noexec,nosuid,size=100m
      - /var/run/postgresql:noexec,nosuid,size=50m
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    cap_add:
      - CHOWN
      - DAC_OVERRIDE
      - FOWNER
      - SETGID
      - SETUID
    user: "999:999"
```

### Network Security

```bash
# Firewall configuration with UFW
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH
sudo ufw allow ssh

# Allow HTTP/HTTPS (for nginx)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Allow Ghostfolio only from localhost (nginx proxy)
sudo ufw allow from 127.0.0.1 to any port 8061

# Block direct access to database ports
sudo ufw deny 5432/tcp
sudo ufw deny 6379/tcp

# Enable logging
sudo ufw logging on

# Enable firewall
sudo ufw --force enable

# Check status
sudo ufw status verbose
```

### Fail2ban Configuration

```bash
# Install fail2ban
sudo apt update && sudo apt install fail2ban

# Configure fail2ban for nginx
sudo cat << 'EOF' > /etc/fail2ban/jail.local
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5
backend = systemd

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
logpath = /var/log/nginx/error.log

[nginx-noscript]
enabled = true
port = http,https
filter = nginx-noscript
logpath = /var/log/nginx/access.log
maxretry = 6

[nginx-badbots]
enabled = true
port = http,https
filter = nginx-badbots
logpath = /var/log/nginx/access.log
maxretry = 2

[nginx-noproxy]
enabled = true
port = http,https
filter = nginx-noproxy
logpath = /var/log/nginx/access.log
maxretry = 2
EOF

sudo systemctl restart fail2ban
sudo systemctl enable fail2ban
```

## 🏥 Automated Health Checks

### Comprehensive Health Monitoring

```bash
cat << 'EOF' > health-monitor.sh
#!/bin/bash

WEBHOOK_URL="https://your-monitoring-service.com/webhook"  # Optional
LOG_FILE="/var/log/ghostfolio-health.log"
ALERT_THRESHOLD=3
ALERT_COUNT_FILE="/tmp/ghostfolio-alert-count"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

send_alert() {
    local message="$1"
    log_message "ALERT: $message"
    
    # Increment alert count
    local count=1
    if [ -f "$ALERT_COUNT_FILE" ]; then
        count=$(cat "$ALERT_COUNT_FILE")
        count=$((count + 1))
    fi
    echo "$count" > "$ALERT_COUNT_FILE"
    
    # Send webhook if configured and threshold reached
    if [ -n "$WEBHOOK_URL" ] && [ "$count" -ge "$ALERT_THRESHOLD" ]; then
        curl -X POST "$WEBHOOK_URL" \
             -H "Content-Type: application/json" \
             -d "{\"text\":\"Ghostfolio Alert: $message\"}" 2>/dev/null || true
        echo "0" > "$ALERT_COUNT_FILE"  # Reset counter after sending
    fi
}

check_container_health() {
    local service="$1"
    if ! docker compose ps | grep -q "$service.*Up"; then
        send_alert "$service container is not running"
        return 1
    fi
    return 0
}

check_http_health() {
    if ! curl -sf http://localhost:8061/api/v1/health >/dev/null; then
        send_alert "Ghostfolio HTTP health check failed"
        return 1
    fi
    return 0
}

check_database_health() {
    if ! docker compose exec postgres pg_isready -U ghostfolio >/dev/null 2>&1; then
        send_alert "PostgreSQL health check failed"
        return 1
    fi
    return 0
}

check_redis_health() {
    if ! docker compose exec redis redis-cli ping >/dev/null 2>&1; then
        send_alert "Redis health check failed"
        return 1
    fi
    return 0
}

check_disk_space() {
    local usage=$(df /opt/ghostfolio | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$usage" -gt 85 ]; then
        send_alert "Disk space usage is $usage% (threshold: 85%)"
        return 1
    fi
    return 0
}

check_memory_usage() {
    local usage=$(free | grep Mem | awk '{printf("%.0f", $3/$2 * 100)}')
    if [ "$usage" -gt 90 ]; then
        send_alert "Memory usage is $usage% (threshold: 90%)"
        return 1
    fi
    return 0
}

# Run all health checks
log_message "Starting health checks"

health_ok=true

check_container_health "ghostfolio" || health_ok=false
check_container_health "postgres" || health_ok=false
check_container_health "redis" || health_ok=false

check_http_health || health_ok=false
check_database_health || health_ok=false
check_redis_health || health_ok=false

check_disk_space || health_ok=false
check_memory_usage || health_ok=false

if [ "$health_ok" = true ]; then
    log_message "All health checks passed"
    # Reset alert counter on success
    echo "0" > "$ALERT_COUNT_FILE"
else
    log_message "Some health checks failed"
fi

# Rotate log file
if [ -f "$LOG_FILE" ] && [ $(stat -c%s "$LOG_FILE") -gt 5242880 ]; then  # 5MB
    mv "$LOG_FILE" "${LOG_FILE}.$(date +%Y%m%d_%H%M%S)"
    gzip "${LOG_FILE}.$(date +%Y%m%d_%H%M%S)"
fi
EOF

chmod +x health-monitor.sh

# Schedule health checks every 2 minutes
echo "*/2 * * * * /path/to/ghostfolio-docker/health-monitor.sh" | crontab -
```

## ⚖️ Load Balancing & Scaling

### Multi-Instance Setup

```yaml
# docker-compose.scale.yml - For load balancing
version: '3.8'

services:
  ghostfolio-1:
    extends:
      file: docker-compose.yml
      service: ghostfolio
    container_name: ${PROJECT_NAME}-ghostfolio-1
    
  ghostfolio-2:
    extends:
      file: docker-compose.yml
      service: ghostfolio
    container_name: ${PROJECT_NAME}-ghostfolio-2
    
  nginx-lb:
    image: nginx:alpine
    container_name: ${PROJECT_NAME}-nginx-lb
    ports:
      - "${EXTERNAL_PORT}:80"
    volumes:
      - ./nginx-lb.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - ghostfolio-1
      - ghostfolio-2
```

### HAProxy Load Balancer

```bash
# HAProxy configuration
cat << 'EOF' > haproxy.cfg
global
    daemon
    maxconn 4096
    
defaults
    mode http
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms
    option httplog
    
frontend ghostfolio_frontend
    bind *:8061
    default_backend ghostfolio_backend
    
backend ghostfolio_backend
    balance roundrobin
    option httpchk GET /api/v1/health
    server ghostfolio-1 ghostfolio-1:3333 check
    server ghostfolio-2 ghostfolio-2:3333 check
    
stats enable
stats uri /stats
stats refresh 30s
EOF

# Add HAProxy to docker-compose.yml
cat << 'EOF' >> docker-compose.scale.yml
  haproxy:
    image: haproxy:alpine
    container_name: ${PROJECT_NAME}-haproxy
    ports:
      - "${EXTERNAL_PORT}:8061"
      - "8404:8404"  # Stats
    volumes:
      - ./haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro
    depends_on:
      - ghostfolio-1
      - ghostfolio-2
EOF
```

## 🆘 Disaster Recovery

### Automated Backup Strategy

```bash
cat << 'EOF' > disaster-recovery.sh
#!/bin/bash

BACKUP_BASE="/opt/ghostfolio/backups"
REMOTE_BACKUP="user@backup-server:/backups/ghostfolio"
RETENTION_DAYS=30

create_full_backup() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="$BACKUP_BASE/full_$timestamp"
    
    echo "Creating full backup: $backup_dir"
    mkdir -p "$backup_dir"
    
    # Stop services for consistent backup
    docker compose stop
    
    # Backup volumes
    tar -czf "$backup_dir/volumes.tar.gz" -C /opt/ghostfolio data/
    
    # Backup configuration
    tar -czf "$backup_dir/config.tar.gz" \
        docker-compose.yml .env .db.env \
        nginx/ scripts/ docs/
    
    # Database dump
    docker compose start postgres
    sleep 10
    docker compose exec postgres pg_dump -U ghostfolio ghostfolio | gzip > "$backup_dir/database.sql.gz"
    
    # Start all services
    docker compose start
    
    # Create manifest
    cat << MANIFEST > "$backup_dir/manifest.txt"
Ghostfolio Full Backup
Created: $(date)
Version: $(cat VERSION 2>/dev/null || echo "unknown")
Hostname: $(hostname)
Size: $(du -sh "$backup_dir" | cut -f1)
MANIFEST
    
    echo "Full backup completed: $backup_dir"
    
    # Sync to remote if configured
    if [ -n "$REMOTE_BACKUP" ]; then
        rsync -avz "$backup_dir/" "$REMOTE_BACKUP/full_$timestamp/"
        echo "Backup synced to remote: $REMOTE_BACKUP/full_$timestamp/"
    fi
}

cleanup_old_backups() {
    echo "Cleaning up backups older than $RETENTION_DAYS days"
    find "$BACKUP_BASE" -name "full_*" -type d -mtime +$RETENTION_DAYS -exec rm -rf {} \;
    
    # Clean remote backups
    if [ -n "$REMOTE_BACKUP" ]; then
        ssh "${REMOTE_BACKUP%:*}" "find ${REMOTE_BACKUP#*:} -name 'full_*' -type d -mtime +$RETENTION_DAYS -exec rm -rf {} \;"
    fi
}

restore_from_backup() {
    local backup_path="$1"
    
    if [ ! -d "$backup_path" ]; then
        echo "Backup path not found: $backup_path"
        exit 1
    fi
    
    echo "Restoring from backup: $backup_path"
    
    # Stop services
    docker compose down
    
    # Restore volumes
    if [ -f "$backup_path/volumes.tar.gz" ]; then
        echo "Restoring volumes..."
        tar -xzf "$backup_path/volumes.tar.gz" -C /opt/ghostfolio/
    fi
    
    # Restore configuration
    if [ -f "$backup_path/config.tar.gz" ]; then
        echo "Restoring configuration..."
        tar -xzf "$backup_path/config.tar.gz"
    fi
    
    # Start services
    docker compose up -d
    
    # Restore database
    if [ -f "$backup_path/database.sql.gz" ]; then
        echo "Restoring database..."
        sleep 30  # Wait for PostgreSQL to start
        zcat "$backup_path/database.sql.gz" | docker compose exec -T postgres psql -U ghostfolio ghostfolio
    fi
    
    echo "Restore completed successfully"
}

# Main execution
case "$1" in
    backup)
        create_full_backup
        cleanup_old_backups
        ;;
    restore)
        restore_from_backup "$2"
        ;;
    cleanup)
        cleanup_old_backups
        ;;
    *)
        echo "Usage: $0 {backup|restore <path>|cleanup}"
        exit 1
        ;;
esac
EOF

chmod +x disaster-recovery.sh

# Schedule daily disaster recovery backups
echo "0 2 * * * /path/to/ghostfolio-docker/disaster-recovery.sh backup" | crontab -
```

---

💡 **Pro Tip**: Monitor all these optimizations and adjust based on your actual usage patterns. What works for one deployment may need tweaking for another based on user load, data size, and hardware specifications.
