#!/bin/bash

# =============================================================================
# GHOSTFOLIO DEPLOYMENT SCRIPT
# =============================================================================
# Automated setup script for deploying Ghost    # Test if Ghostfolio is responding
    log_info "Testing ${PROJECT_NAME^} application..."
    if curl -s -f "http://localhost:${EXTERNAL_PORT}/api/v1/health" > /dev/null; then
        log_success "${PROJECT_NAME^} is responding on port ${EXTERNAL_PORT}"
    else
        log_warning "${PROJECT_NAME^} may still be starting up"
        log_info "Check logs with: docker compose logs ${PROJECT_NAME}"
    fi
    
    # Display connection information
    echo
    log_success "Deployment completed successfully!"
    echo
    echo "Next steps:"
    echo "1. Open http://localhost:${EXTERNAL_PORT} in your browser"
    echo "2. Create the first admin user account"
    echo "3. Configure nginx reverse proxy to forward ${BASE_DOMAIN} to localhost:${EXTERNAL_PORT}"
    echoCompose
#
# This script handles:
# - Directory structure creation
# - Environment file setup
# - Docker Compose deployment
# - Initial configuration verification
#
# Usage: ./deploy.sh [options]
# Options:
#   --setup-only    Only create directories and copy env files
#   --start-only    Only start services (skip setup)
#   --help          Show this help message
# =============================================================================

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# -----------------------------------------------------------------------------
# CONFIGURATION
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment variables if .env exists
if [[ -f "$SCRIPT_DIR/.env" ]]; then
    source "$SCRIPT_DIR/.env"
fi

# Use environment variables with fallbacks for initial setup
PROJECT_NAME="${PROJECT_NAME:-ghostfolio}"
BASE_DIR="${DATA_BASE_PATH:-/var/www/folio.dmla.tech}"
EXTERNAL_PORT="${EXTERNAL_PORT:-8061}"
BASE_DOMAIN="${BASE_DOMAIN:-localhost}"

DOCKER_COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"
ENV_FILE="$SCRIPT_DIR/.env"
DB_ENV_FILE="$SCRIPT_DIR/.db.env"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
Ghostfolio Deployment Script

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --setup-only     Only create directories and environment files
    --start-only     Only start Docker services (skip setup)
    --help          Show this help message

EXAMPLES:
    $0                    # Full deployment (setup + start)
    $0 --setup-only       # Setup directories and files only
    $0 --start-only       # Start services only

DESCRIPTION:
    This script automates the deployment of Ghostfolio using Docker Compose.
    It creates the required directory structure, sets up environment files,
    and starts the Docker services.

REQUIREMENTS:
    - Docker and Docker Compose installed
    - Sudo privileges for directory creation
    - Network access for pulling Docker images

EOF
}

# -----------------------------------------------------------------------------
# VALIDATION FUNCTIONS
# -----------------------------------------------------------------------------
check_requirements() {
    log_info "Checking system requirements..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker &> /dev/null || ! docker compose version &> /dev/null; then
        log_error "Docker Compose is not available"
        exit 1
    fi
    
    # Check if running as root or with sudo access
    if [[ $EUID -ne 0 ]] && ! sudo -n true 2>/dev/null; then
        log_error "This script requires sudo privileges for directory creation"
        exit 1
    fi
    
    log_success "System requirements check passed"
}

# -----------------------------------------------------------------------------
# DIRECTORY SETUP
# -----------------------------------------------------------------------------
create_directories() {
    log_info "Creating directory structure at $BASE_DIR..."
    
    # Create main directories with appropriate permissions
    sudo mkdir -p "$BASE_DIR"/{data/{db/postgre,cache/redis,storage},logs/{postgres,redis}}
    
    # Set ownership to current user for easier management
    sudo chown -R "$(id -u):$(id -g)" "$BASE_DIR"
    
    # Set secure permissions
    chmod 755 "$BASE_DIR"
    chmod 755 "$BASE_DIR"/{data,logs}
    chmod 755 "$BASE_DIR"/data/{db,cache,storage}
    chmod 755 "$BASE_DIR"/logs/{postgres,redis}
    chmod 700 "$BASE_DIR"/data/db/postgre  # Database files should be private
    chmod 700 "$BASE_DIR"/data/cache/redis  # Cache files should be private
    
    log_success "Directory structure created successfully"
}

# -----------------------------------------------------------------------------
# ENVIRONMENT FILE SETUP
# -----------------------------------------------------------------------------
setup_environment_files() {
    log_info "Setting up environment files..."
    
    # Check if .env file exists
    if [[ ! -f "$ENV_FILE" ]]; then
        if [[ -f "$ENV_FILE.example" ]]; then
            cp "$ENV_FILE.example" "$ENV_FILE"
            log_warning "Created .env from .env.example - PLEASE CONFIGURE SECRETS!"
        else
            log_error ".env.example file not found"
            exit 1
        fi
    else
        log_info ".env file already exists"
    fi
    
    # Check if .db.env file exists
    if [[ ! -f "$DB_ENV_FILE" ]]; then
        if [[ -f "$DB_ENV_FILE.example" ]]; then
            cp "$DB_ENV_FILE.example" "$DB_ENV_FILE"
            log_warning "Created .db.env from .db.env.example - PLEASE CONFIGURE PASSWORDS!"
        else
            log_error ".db.env.example file not found"
            exit 1
        fi
    else
        log_info ".db.env file already exists"
    fi
    
    # Set secure permissions on environment files
    chmod 600 "$ENV_FILE" "$DB_ENV_FILE"
    
    # Check for default/example values
    if grep -q "CHANGE_THIS" "$ENV_FILE" || grep -q "CHANGE_THIS" "$DB_ENV_FILE"; then
        log_error "Environment files contain default values that must be changed!"
        log_error "Please edit .env and .db.env files and replace all 'CHANGE_THIS' values"
        log_error "Generate secure passwords using: openssl rand -base64 32"
        exit 1
    fi
    
    log_success "Environment files configured"
}

# -----------------------------------------------------------------------------
# DOCKER OPERATIONS
# -----------------------------------------------------------------------------
start_services() {
    log_info "Starting Ghostfolio services with Docker Compose..."
    
    # Change to script directory for relative paths
    cd "$SCRIPT_DIR"
    
    # Pull latest images
    log_info "Pulling Docker images..."
    docker compose pull
    
    # Start services in background
    log_info "Starting services..."
    docker compose up -d
    
    # Wait for services to be healthy
    log_info "Waiting for services to be ready..."
    local max_attempts=60
    local attempt=0
    
    while [[ $attempt -lt $max_attempts ]]; do
        if docker compose ps | grep -q "Up (healthy)"; then
            log_success "Services are running and healthy"
            break
        fi
        
        ((attempt++))
        if [[ $attempt -eq $max_attempts ]]; then
            log_error "Services failed to start within expected time"
            log_error "Check service logs: docker compose logs"
            exit 1
        fi
        
        echo -n "."
        sleep 2
    done
    echo
}

# -----------------------------------------------------------------------------
# POST-DEPLOYMENT VERIFICATION
# -----------------------------------------------------------------------------
verify_deployment() {
    log_info "Verifying deployment..."
    
    # Check service status
    log_info "Service status:"
    docker compose ps
    
    # Check if Ghostfolio is responding
    log_info "Testing Ghostfolio application..."
    if curl -s -f http://localhost:8061/api/v1/health > /dev/null; then
        log_success "Ghostfolio is responding on port 8061"
    else
        log_warning "Ghostfolio may still be starting up"
        log_info "Check logs with: docker compose logs ghostfolio"
    fi
    
    # Display connection information
    echo
    log_success "Deployment completed successfully!"
    echo
    echo "Next steps:"
    echo "1. Open http://localhost:8061 in your browser"
    echo "2. Create the first admin user account"
    echo "3. Configure nginx reverse proxy to forward folio.dmla.tech to localhost:8061"
    echo
    echo "Useful commands:"
    echo "  View logs:    docker compose logs -f"
    echo "  Stop services: docker compose down"
    echo "  Update:       docker compose pull && docker compose up -d"
    echo
}

# -----------------------------------------------------------------------------
# MAIN EXECUTION
# -----------------------------------------------------------------------------
main() {
    local setup_only=false
    local start_only=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --setup-only)
                setup_only=true
                shift
                ;;
            --start-only)
                start_only=true
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
    if [[ "$setup_only" == true && "$start_only" == true ]]; then
        log_error "Cannot use --setup-only and --start-only together"
        exit 1
    fi
    
    # Execute based on options
    if [[ "$start_only" == false ]]; then
        log_info "Starting Ghostfolio deployment setup..."
        check_requirements
        create_directories
        setup_environment_files
        
        if [[ "$setup_only" == true ]]; then
            log_success "Setup completed. Run '$0 --start-only' to start services."
            exit 0
        fi
    fi
    
    if [[ "$setup_only" == false ]]; then
        check_requirements
        start_services
        verify_deployment
    fi
}

# Run main function with all arguments
main "$@"
