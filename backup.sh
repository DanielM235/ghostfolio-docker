#!/bin/bash

# =============================================================================
# GHOSTFOLIO BACKUP SCRIPT
# =============================================================================
# Comprehensive backup solution for Ghostfolio Docker deployment
#
# This script creates backups of:
# - PostgreSQL database (SQL dump)
# - Redis data (RDB snapshot)
# - User uploaded files and storage
# - Configuration files
#
# Usage: ./backup.sh [options]
# Options:
#   --db-only       Backup database only
#   --files-only    Backup files only
#   --config-only   Backup configuration only
#   --compress      Create compressed archive
#   --help          Show help message
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# CONFIGURATION
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="/var/www/folio.dmla.tech"
BACKUP_DIR="/var/backups/ghostfolio"
DATE_FORMAT=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="ghostfolio_backup_$DATE_FORMAT"

# Docker Compose settings
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"
POSTGRES_CONTAINER="ghostfolio_postgres"
REDIS_CONTAINER="ghostfolio_redis"

# Retention settings
KEEP_BACKUPS=30  # Keep last 30 backups

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# -----------------------------------------------------------------------------
# LOGGING FUNCTIONS
# -----------------------------------------------------------------------------
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# -----------------------------------------------------------------------------
# HELP FUNCTION
# -----------------------------------------------------------------------------
show_help() {
    cat << EOF
Ghostfolio Backup Script

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --db-only        Backup database only (PostgreSQL + Redis)
    --files-only     Backup user files and storage only
    --config-only    Backup configuration files only
    --compress       Create compressed tar.gz archive
    --help          Show this help message

EXAMPLES:
    $0                    # Full backup (all components)
    $0 --db-only          # Database backup only
    $0 --compress         # Full backup with compression

BACKUP LOCATION:
    $BACKUP_DIR

RETENTION:
    Automatically keeps last $KEEP_BACKUPS backups
EOF
}

# -----------------------------------------------------------------------------
# VALIDATION FUNCTIONS
# -----------------------------------------------------------------------------
check_requirements() {
    log_info "Checking backup requirements..."
    
    # Check if Docker is running
    if ! docker info &> /dev/null; then
        log_error "Docker is not running or accessible"
        exit 1
    fi
    
    # Check if containers are running
    if ! docker compose -f "$COMPOSE_FILE" ps | grep -q "Up"; then
        log_error "Ghostfolio services are not running"
        exit 1
    fi
    
    # Create backup directory
    sudo mkdir -p "$BACKUP_DIR"
    sudo chown "$(id -u):$(id -g)" "$BACKUP_DIR"
    
    log_success "Requirements check passed"
}

# -----------------------------------------------------------------------------
# DATABASE BACKUP FUNCTIONS
# -----------------------------------------------------------------------------
backup_postgresql() {
    log_info "Backing up PostgreSQL database..."
    
    local backup_file="$1/postgresql_dump.sql"
    
    # Load database environment variables
    source "$SCRIPT_DIR/.db.env"
    
    # Create database dump
    docker compose -f "$COMPOSE_FILE" exec -T postgres pg_dump \
        -U "$POSTGRES_USER" \
        -d "$POSTGRES_DB" \
        --clean \
        --if-exists \
        --create \
        --verbose > "$backup_file"
    
    # Verify backup file
    if [[ -s "$backup_file" ]]; then
        log_success "PostgreSQL backup completed: $(du -h "$backup_file" | cut -f1)"
    else
        log_error "PostgreSQL backup failed or is empty"
        return 1
    fi
}

backup_redis() {
    log_info "Backing up Redis data..."
    
    local backup_dir="$1"
    
    # Trigger Redis BGSAVE
    docker compose -f "$COMPOSE_FILE" exec redis redis-cli BGSAVE
    
    # Wait for background save to complete
    log_info "Waiting for Redis background save to complete..."
    while [[ $(docker compose -f "$COMPOSE_FILE" exec redis redis-cli LASTSAVE) -eq $(docker compose -f "$COMPOSE_FILE" exec redis redis-cli LASTSAVE) ]]; do
        sleep 1
    done
    
    # Copy Redis data files
    docker cp "$REDIS_CONTAINER:/data/dump.rdb" "$backup_dir/redis_dump.rdb" 2>/dev/null || {
        log_warning "Redis dump.rdb not found, copying all Redis data"
        mkdir -p "$backup_dir/redis_data"
        docker cp "$REDIS_CONTAINER:/data/." "$backup_dir/redis_data/"
    }
    
    log_success "Redis backup completed"
}

# -----------------------------------------------------------------------------
# FILE BACKUP FUNCTIONS
# -----------------------------------------------------------------------------
backup_files() {
    log_info "Backing up user files and storage..."
    
    local backup_dir="$1"
    
    # Create storage backup directory
    mkdir -p "$backup_dir/storage"
    
    # Copy storage files
    if [[ -d "$BASE_DIR/data/storage" ]] && [[ "$(ls -A "$BASE_DIR/data/storage")" ]]; then
        cp -r "$BASE_DIR/data/storage"/* "$backup_dir/storage/"
        log_success "Storage files backup completed: $(du -sh "$backup_dir/storage" | cut -f1)"
    else
        log_info "No user storage files to backup"
        touch "$backup_dir/storage/.empty"
    fi
}

backup_logs() {
    log_info "Backing up application logs..."
    
    local backup_dir="$1"
    
    # Create logs backup directory
    mkdir -p "$backup_dir/logs"
    
    # Copy log files (last 7 days only to manage size)
    if [[ -d "$BASE_DIR/logs" ]]; then
        find "$BASE_DIR/logs" -name "*.log" -mtime -7 -exec cp {} "$backup_dir/logs/" \; 2>/dev/null || true
        log_success "Recent logs backup completed"
    else
        log_info "No log files to backup"
        touch "$backup_dir/logs/.empty"
    fi
}

# -----------------------------------------------------------------------------
# CONFIGURATION BACKUP FUNCTIONS
# -----------------------------------------------------------------------------
backup_config() {
    log_info "Backing up configuration files..."
    
    local backup_dir="$1"
    
    # Create config backup directory
    mkdir -p "$backup_dir/config"
    
    # Copy configuration files (excluding secrets)
    cp "$SCRIPT_DIR/docker-compose.yml" "$backup_dir/config/"
    
    # Copy environment files with secrets masked
    sed 's/=.*/=***MASKED***/g' "$SCRIPT_DIR/.env.example" > "$backup_dir/config/env.example"
    sed 's/=.*/=***MASKED***/g' "$SCRIPT_DIR/.db.env.example" > "$backup_dir/config/db.env.example"
    
    # Copy other documentation
    [[ -f "$SCRIPT_DIR/README.md" ]] && cp "$SCRIPT_DIR/README.md" "$backup_dir/config/"
    [[ -f "$SCRIPT_DIR/.copilot-instructions.md" ]] && cp "$SCRIPT_DIR/.copilot-instructions.md" "$backup_dir/config/"
    
    log_success "Configuration backup completed"
}

# -----------------------------------------------------------------------------
# COMPRESSION AND CLEANUP
# -----------------------------------------------------------------------------
create_archive() {
    local source_dir="$1"
    local archive_name="${source_dir}.tar.gz"
    
    log_info "Creating compressed archive..."
    
    tar -czf "$archive_name" -C "$(dirname "$source_dir")" "$(basename "$source_dir")"
    
    # Remove uncompressed directory
    rm -rf "$source_dir"
    
    log_success "Archive created: $archive_name ($(du -h "$archive_name" | cut -f1))"
    echo "$archive_name"
}

cleanup_old_backups() {
    log_info "Cleaning up old backups (keeping last $KEEP_BACKUPS)..."
    
    # Find and remove old backups
    find "$BACKUP_DIR" -name "ghostfolio_backup_*" -type f -o -name "ghostfolio_backup_*" -type d | \
        sort -r | \
        tail -n +$((KEEP_BACKUPS + 1)) | \
        xargs -r rm -rf
    
    log_success "Cleanup completed"
}

# -----------------------------------------------------------------------------
# MAIN BACKUP FUNCTION
# -----------------------------------------------------------------------------
perform_backup() {
    local db_only="$1"
    local files_only="$2"
    local config_only="$3"
    local compress="$4"
    
    # Create backup directory
    local backup_path="$BACKUP_DIR/$BACKUP_NAME"
    mkdir -p "$backup_path"
    
    # Create backup metadata
    cat > "$backup_path/backup_info.txt" << EOF
Ghostfolio Backup Information
=============================
Backup Date: $(date)
Backup Type: $([ "$db_only" = true ] && echo "Database Only" || [ "$files_only" = true ] && echo "Files Only" || [ "$config_only" = true ] && echo "Configuration Only" || echo "Full Backup")
Ghostfolio Version: $(docker compose -f "$COMPOSE_FILE" ps ghostfolio --format "table {{.Image}}" | tail -n1)
Script Version: 1.0
EOF
    
    # Perform backups based on options
    if [[ "$config_only" != true ]]; then
        if [[ "$files_only" != true ]]; then
            backup_postgresql "$backup_path"
            backup_redis "$backup_path"
        fi
        
        if [[ "$db_only" != true ]]; then
            backup_files "$backup_path"
            backup_logs "$backup_path"
        fi
    fi
    
    if [[ "$db_only" != true && "$files_only" != true ]] || [[ "$config_only" == true ]]; then
        backup_config "$backup_path"
    fi
    
    # Create archive if requested
    if [[ "$compress" == true ]]; then
        local archive_path
        archive_path=$(create_archive "$backup_path")
        log_success "Backup completed: $archive_path"
    else
        log_success "Backup completed: $backup_path"
    fi
    
    # Cleanup old backups
    cleanup_old_backups
}

# -----------------------------------------------------------------------------
# MAIN EXECUTION
# -----------------------------------------------------------------------------
main() {
    local db_only=false
    local files_only=false
    local config_only=false
    local compress=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --db-only)
                db_only=true
                shift
                ;;
            --files-only)
                files_only=true
                shift
                ;;
            --config-only)
                config_only=true
                shift
                ;;
            --compress)
                compress=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Validate conflicting options
    local option_count=0
    [[ "$db_only" == true ]] && ((option_count++))
    [[ "$files_only" == true ]] && ((option_count++))
    [[ "$config_only" == true ]] && ((option_count++))
    
    if [[ $option_count -gt 1 ]]; then
        log_error "Cannot use multiple exclusive backup options together"
        exit 1
    fi
    
    # Start backup process
    log_info "Starting Ghostfolio backup process..."
    
    check_requirements
    perform_backup "$db_only" "$files_only" "$config_only" "$compress"
    
    log_success "Backup process completed successfully!"
}

# Run main function with all arguments
main "$@"
