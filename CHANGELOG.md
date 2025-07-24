# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Version tracking system with VERSION file
- Comprehensive changelog documentation

### Changed
- Nothing yet

### Deprecated
- Nothing yet

### Removed
- Nothing yet

### Fixed
- Nothing yet

### Security
- Nothing yet

## [1.0.0] - 2025-01-24

### Added
- Initial release of Ghostfolio Docker deployment
- Production-ready Docker Compose configuration
- Support for Ghostfolio v2.184.0
- PostgreSQL 16 with optimized settings
- Redis 7 for caching and session management
- Comprehensive environment variable configuration
- Automated deployment script (`deploy.sh`)
- Backup and restore script (`backup.sh`) 
- Safe update script with rollback (`update.sh`)
- Complete documentation and setup guides
- Security best practices implementation
- Health checks for all services
- Resource limits and restart policies
- Isolated Docker networking
- Flexible volume configuration
- Comprehensive logging and monitoring
- nginx reverse proxy configuration examples

### Security
- Environment-based secrets management
- Secure file permissions (600) for environment files
- Database and Redis password protection
- Network isolation between services
- No hardcoded sensitive information in repository

## [0.9.0] - 2025-01-20 (Beta)

### Added
- Initial beta version for testing
- Basic Docker Compose setup
- Environment file templates
- Basic documentation

### Known Issues
- Hardcoded paths and domains (fixed in 1.0.0)
- Limited error handling (improved in 1.0.0)

---

## Version Schema

This project uses [Semantic Versioning](https://semver.org/):

- **MAJOR** version when you make incompatible API changes
- **MINOR** version when you add functionality in a backwards compatible manner  
- **PATCH** version when you make backwards compatible bug fixes

### What constitutes a breaking change?

- Changes to Docker Compose file structure that require manual intervention
- Changes to environment variable names or formats
- Changes to volume mount paths or structure
- Changes to network configuration
- Removal of script functionality or command-line options

### What constitutes a minor version?

- New optional features or configuration options
- New scripts or utilities
- Enhanced documentation
- Performance improvements
- Support for new Ghostfolio versions (when compatible)

### What constitutes a patch version?

- Bug fixes
- Security patches
- Documentation updates
- Minor script improvements
- Dependency updates (when compatible)
