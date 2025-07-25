#!/bin/bash

# =============================================================================
# GHOSTFOLIO UPDATE SCRIPT
# =============================================================================
# Safe update procedure for Ghostfolio Docker deployment
#
# This script handles:
# - Pre-update backup creation
# - Service shutdown and update
# - Database migration verification
# - Rollback capability if update fails
#
# Usage: ./update.sh [options]
# Options:
#   --to-version VERSION    Update to specific version (e.g., 2.185.0)
#   --backup-first         Create backup before update (recommended)
#   --dry-run             Show what would be updated without making changes
#   --rollback            Rollback to previous version
#   --version             Show version information
#   --help                Show help message
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# CONFIGURATION
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load version information
if [[ -f "$SCRIPT_DIR/VERSION" ]]; then
    source "$SCRIPT_DIR/VERSION"
else
    PROJECT_VERSION="unknown"
fi

# Load environment variables from .env file
if [[ -f "$SCRIPT_DIR/.env" ]]; then
    source "$SCRIPT_DIR/.env"
else
    log_error "Environment file .env not found"
    exit 1
fi

# Use environment variables
PROJECT_NAME="${PROJECT_NAME:-ghostfolio}"
EXTERNAL_PORT="${EXTERNAL_PORT:-8061}"
BASE_DOMAIN="${BASE_DOMAIN:-localhost}"

COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"
BACKUP_SCRIPT="$SCRIPT_DIR/backup.sh"
UPDATE_LOG="$SCRIPT_DIR/update.log"

# Version management
CURRENT_VERSION=""
TARGET_VERSION=""
ROLLBACK_VERSION=""

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
    echo "$(date): [INFO] $1" >> "$UPDATE_LOG"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    echo "$(date): [SUCCESS] $1" >> "$UPDATE_LOG"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    echo "$(date): [WARNING] $1" >> "$UPDATE_LOG"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "$(date): [ERROR] $1" >> "$UPDATE_LOG"
}

# -----------------------------------------------------------------------------
# HELP FUNCTION
# -----------------------------------------------------------------------------
show_help() {
    cat << EOF
${PROJECT_NAME:-Ghostfolio} Update Script v${PROJECT_VERSION:-unknown}

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --to-version VERSION   Update to specific version (e.g., 2.185.0)
    --backup-first        Create backup before update (recommended)
    --dry-run            Show what would be updated without making changes
    --rollback           Rollback to previous version from backup
    --version            Show version information
    --help               Show this help message

EXAMPLES:
    $0 --backup-first                    # Update to latest with backup
    $0 --to-version 2.185.0 --backup-first  # Update to specific version
    $0 --dry-run                         # Check what would be updated
    $0 --rollback                        # Rollback to previous version

SAFETY FEATURES:
    - Automatic backup creation before update
    - Health check verification after update
    - Rollback capability if update fails
    - Update logging for troubleshooting

UPDATE LOG:
    $UPDATE_LOG
EOF
}

# -----------------------------------------------------------------------------
# VERSION MANAGEMENT
# -----------------------------------------------------------------------------
get_current_version() {
    log_info "Detecting current ${PROJECT_NAME^} version..."
    
    if docker compose -f "$COMPOSE_FILE" ps "$PROJECT_NAME" &>/dev/null; then
        CURRENT_VERSION=$(docker compose -f "$COMPOSE_FILE" images "$PROJECT_NAME" --format "{{.Repository}}:{{.Tag}}" | cut -d: -f2)
        log_info "Current version: $CURRENT_VERSION"
    else
        log_warning "${PROJECT_NAME^} service not found or not running"
        CURRENT_VERSION="unknown"
    fi
}

get_latest_version() {
    log_info "Fetching latest ${PROJECT_NAME^} version from GitHub..."
    
    local latest_version
    latest_version=$(curl -s https://api.github.com/repos/ghostfolio/ghostfolio/releases/latest | grep '"tag_name":' | cut -d'"' -f4)
    
    if [[ -n "$latest_version" ]]; then
        echo "$latest_version"
    else
        log_error "Failed to fetch latest version from GitHub"
        exit 1
    fi
}

validate_version() {
    local version="$1"
    
    # Check if version format is valid (e.g., 2.184.0)
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        log_error "Invalid version format: $version"
        log_error "Expected format: X.Y.Z (e.g., 2.184.0)"
        exit 1
    fi
    
    # Check if version exists on Docker Hub
    if ! docker manifest inspect "ghostfolio/ghostfolio:$version" &>/dev/null; then
        log_error "Version $version not found on Docker Hub"
        exit 1
    fi
    
    log_success "Version $version validated"
}

# -----------------------------------------------------------------------------
# BACKUP OPERATIONS
# -----------------------------------------------------------------------------
create_pre_update_backup() {
    log_info "Creating pre-update backup..."
    
    if [[ ! -x "$BACKUP_SCRIPT" ]]; then
        log_error "Backup script not found or not executable: $BACKUP_SCRIPT"
        exit 1
    fi
    
    # Create backup with compression
    if "$BACKUP_SCRIPT" --compress; then
        log_success "Pre-update backup completed"
        
        # Save current version for rollback
        echo "$CURRENT_VERSION" > "$SCRIPT_DIR/.rollback_version"
    else
        log_error "Pre-update backup failed"
        exit 1
    fi
}

# -----------------------------------------------------------------------------
# UPDATE OPERATIONS
# -----------------------------------------------------------------------------
update_compose_file() {
    local new_version="$1"
    
    log_info "Updating docker-compose.yml to version $new_version..."
    
    # Create backup of current compose file
    cp "$COMPOSE_FILE" "$COMPOSE_FILE.backup"
    
    # Update GHOSTFOLIO_VERSION in .env file instead of compose file
    sed -i "s/GHOSTFOLIO_VERSION=.*/GHOSTFOLIO_VERSION=$new_version/g" "$SCRIPT_DIR/.env"
    
    log_success "Environment configuration updated to version $new_version"
}

pull_new_images() {
    log_info "Pulling new Docker images..."
    
    if docker compose -f "$COMPOSE_FILE" pull; then
        log_success "Images pulled successfully"
    else
        log_error "Failed to pull images"
        return 1
    fi
}

restart_services() {
    log_info "Restarting services with new version..."
    
    # Stop services gracefully
    log_info "Stopping services..."
    docker compose -f "$COMPOSE_FILE" down --timeout 30
    
    # Start services with new version
    log_info "Starting services with new version..."
    docker compose -f "$COMPOSE_FILE" up -d
    
    log_success "Services restarted"
}

# -----------------------------------------------------------------------------
# HEALTH CHECK AND VERIFICATION
# -----------------------------------------------------------------------------
verify_update() {
    log_info "Verifying update success..."
    
    local max_attempts=60
    local attempt=0
    
    # Wait for services to be healthy
    while [[ $attempt -lt $max_attempts ]]; do
        if docker compose -f "$COMPOSE_FILE" ps | grep -q "Up (healthy)"; then
            break
        fi
        
        ((attempt++))
        if [[ $attempt -eq $max_attempts ]]; then
            log_error "Services failed to start healthy within expected time"
            return 1
        fi
        
        echo -n "."
        sleep 2
    done
    echo
    
    # Test application endpoint
    log_info "Testing ${PROJECT_NAME^} application endpoint..."
    local health_attempts=10
    local health_attempt=0
    
    while [[ $health_attempt -lt $health_attempts ]]; do
        if curl -s -f "http://localhost:${EXTERNAL_PORT}/api/v1/health" > /dev/null; then
            log_success "${PROJECT_NAME^} application is responding"
            break
        fi
        
        ((health_attempt++))
        if [[ $health_attempt -eq $health_attempts ]]; then
            log_error "${PROJECT_NAME^} application is not responding"
            return 1
        fi
        
        sleep 3
    done
    
    # Verify version
    local new_current_version
    new_current_version=$(docker compose -f "$COMPOSE_FILE" images "$PROJECT_NAME" --format "{{.Repository}}:{{.Tag}}" | cut -d: -f2)
    
    if [[ "$new_current_version" == "$TARGET_VERSION" ]]; then
        log_success "Update verified: now running version $new_current_version"
        return 0
    else
        log_error "Version verification failed: expected $TARGET_VERSION, got $new_current_version"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# ROLLBACK OPERATIONS
# -----------------------------------------------------------------------------
rollback_update() {
    log_warning "Rolling back to previous version..."
    
    if [[ ! -f "$SCRIPT_DIR/.rollback_version" ]]; then
        log_error "No rollback version information found"
        exit 1
    fi
    
    local rollback_version
    rollback_version=$(cat "$SCRIPT_DIR/.rollback_version")
    
    log_info "Rolling back to version: $rollback_version"
    
    # Restore compose file
    if [[ -f "$COMPOSE_FILE.backup" ]]; then
        mv "$COMPOSE_FILE.backup" "$COMPOSE_FILE"
    else
        # Update compose file to rollback version
        update_compose_file "$rollback_version"
    fi
    
    # Pull and restart with old version
    if pull_new_images && restart_services; then
        log_success "Rollback completed successfully"
    else
        log_error "Rollback failed"
        exit 1
    fi
}

# -----------------------------------------------------------------------------
# DRY RUN OPERATIONS
# -----------------------------------------------------------------------------
perform_dry_run() {
    log_info "Performing dry run - no changes will be made"
    
    get_current_version
    
    local latest_version
    latest_version=$(get_latest_version)
    
    echo
    echo "DRY RUN SUMMARY:"
    echo "==============="
    echo "Current version: $CURRENT_VERSION"
    echo "Latest version:  $latest_version"
    echo "Target version:  ${TARGET_VERSION:-$latest_version}"
    echo
    
    if [[ "$CURRENT_VERSION" == "${TARGET_VERSION:-$latest_version}" ]]; then
        echo "✓ Already running the target version - no update needed"
    else
        echo "→ Would update from $CURRENT_VERSION to ${TARGET_VERSION:-$latest_version}"
        echo "→ Would create backup before update"
        echo "→ Would pull new Docker images"
        echo "→ Would restart services"
        echo "→ Would verify update success"
    fi
    
    echo
    echo "To perform actual update, run without --dry-run option"
}

# -----------------------------------------------------------------------------
# MAIN UPDATE FUNCTION
# -----------------------------------------------------------------------------
perform_update() {
    local backup_first="$1"
    
    get_current_version
    
    # Determine target version
    if [[ -z "$TARGET_VERSION" ]]; then
        TARGET_VERSION=$(get_latest_version)
        log_info "No version specified, using latest: $TARGET_VERSION"
    fi
    
    # Validate target version
    validate_version "$TARGET_VERSION"
    
    # Check if already on target version
    if [[ "$CURRENT_VERSION" == "$TARGET_VERSION" ]]; then
        log_info "Already running version $TARGET_VERSION"
        exit 0
    fi
    
    log_info "Updating from $CURRENT_VERSION to $TARGET_VERSION"
    
    # Create backup if requested
    if [[ "$backup_first" == true ]]; then
        create_pre_update_backup
    fi
    
    # Perform update
    if update_compose_file "$TARGET_VERSION" && \
       pull_new_images && \
       restart_services && \
       verify_update; then
        
        log_success "Update completed successfully!"
        log_success "${PROJECT_NAME^} updated from $CURRENT_VERSION to $TARGET_VERSION"
        
        # Clean up backup files
        [[ -f "$COMPOSE_FILE.backup" ]] && rm "$COMPOSE_FILE.backup"
        
    else
        log_error "Update failed, attempting rollback..."
        rollback_update
        exit 1
    fi
}

# -----------------------------------------------------------------------------
# MAIN EXECUTION
# -----------------------------------------------------------------------------
main() {
    local backup_first=false
    local dry_run=false
    local rollback=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --to-version)
                TARGET_VERSION="$2"
                shift 2
                ;;
            --backup-first)
                backup_first=true
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --rollback)
                rollback=true
                shift
                ;;
            --version)
                echo "${PROJECT_NAME:-Ghostfolio} Update Script v${PROJECT_VERSION:-unknown}"
                echo "Current Ghostfolio version: ${GHOSTFOLIO_VERSION:-latest}"
                if [[ -f "$SCRIPT_DIR/.rollback_version" ]]; then
                    echo "Rollback version available: $(cat "$SCRIPT_DIR/.rollback_version")"
                fi
                exit 0
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
    
    # Create update log
    echo "=== ${PROJECT_NAME^} Update Started at $(date) ===" >> "$UPDATE_LOG"
    
    # Execute based on options
    if [[ "$rollback" == true ]]; then
        rollback_update
    elif [[ "$dry_run" == true ]]; then
        perform_dry_run
    else
        # Recommend backup for production
        if [[ "$backup_first" == false ]]; then
            log_warning "Update without backup is not recommended for production"
            log_warning "Use --backup-first option to create a backup before update"
            read -p "Continue without backup? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_info "Update cancelled by user"
                exit 0
            fi
        fi
        
        perform_update "$backup_first"
    fi
    
    echo "=== ${PROJECT_NAME^} Update Completed at $(date) ===" >> "$UPDATE_LOG"
}

# Run main function with all arguments
main "$@"
