# Documentation Index

Welcome to the comprehensive documentation for your Ghostfolio Docker deployment. This collection provides detailed guides for managing, troubleshooting, and optimizing your self-hosted Ghostfolio instance.

## 📚 Available Documentation

### 🐳 [Docker Commands & Container Management](docker-commands.md)
Essential Docker Compose commands and container management techniques for your Ghostfolio deployment.

**What you'll learn:**
- Service management (start, stop, restart)
- Container access and debugging
- Database and application container exploration
- Health checks and troubleshooting
- Resource monitoring
- Network debugging

**Best for:** Day-to-day container management and troubleshooting

### 🔗 [Redis Configuration & Management](redis-management.md)
Complete guide to configuring and managing Redis for optimal caching performance.

**What you'll learn:**
- Redis container access and file structure
- Configuration management and tuning
- Performance optimization
- Data management and persistence
- Monitoring and debugging
- Backup and recovery strategies

**Best for:** Redis optimization and cache troubleshooting

### 📊 [Logging & Debugging Guide](logging-debugging.md)
Comprehensive logging strategies and debugging workflows for production environments.

**What you'll learn:**
- Docker and application log management
- Database and system log analysis
- Real-time monitoring techniques
- Log rotation and cleanup
- Debugging workflows for common issues
- Automated log analysis scripts

**Best for:** Troubleshooting issues and monitoring system health

### ✏️ [Text Editors & Development Tools](editors-tools.md)
Guide to text editors and development tools for managing configuration files on Debian systems.

**What you'll learn:**
- Terminal and GUI editor options
- Editor configuration and optimization
- Markdown editing workflows
- SSH and remote editing setup
- File management tools
- Development environment optimization

**Best for:** Setting up an efficient editing environment

### 🔐 [File Permissions & Access Rights](permissions-guide.md)
Complete guide to Linux file permissions, ownership, and access rights management.

**What you'll learn:**
- Understanding Linux permission system
- Docker container user mapping
- Database and application file permissions
- Security best practices
- Troubleshooting permission issues
- Automated permission management

**Best for:** Solving permission issues and securing your deployment

### ⚡ [Advanced Server Optimization](advanced-optimization.md)
Advanced techniques for performance optimization, monitoring, and production hardening.

**What you'll learn:**
- Performance tuning and optimization
- Resource monitoring and alerting
- Network and storage optimization
- Security hardening techniques
- Load balancing and scaling
- Disaster recovery planning

**Best for:** Production deployments and performance optimization

## 🚀 Quick Start Paths

### 🆕 **New to Docker/Linux?**
Start with:
1. [Text Editors & Development Tools](editors-tools.md) - Set up your editing environment
2. [Docker Commands & Container Management](docker-commands.md) - Learn basic container operations
3. [File Permissions & Access Rights](permissions-guide.md) - Understand permission management

### 🔧 **Troubleshooting Issues?**
Go to:
1. [Logging & Debugging Guide](logging-debugging.md) - Diagnose problems
2. [Docker Commands & Container Management](docker-commands.md) - Container health checks
3. [File Permissions & Access Rights](permissions-guide.md) - Fix permission issues

### 🚀 **Optimizing Performance?**
Check:
1. [Redis Configuration & Management](redis-management.md) - Optimize caching
2. [Advanced Server Optimization](advanced-optimization.md) - System-wide optimizations
3. [Logging & Debugging Guide](logging-debugging.md) - Monitor performance

### 🔒 **Securing Production?**
Focus on:
1. [File Permissions & Access Rights](permissions-guide.md) - Secure file access
2. [Advanced Server Optimization](advanced-optimization.md) - Security hardening
3. [Logging & Debugging Guide](logging-debugging.md) - Monitor security events

## 📋 Common Tasks Quick Reference

| Task | Documentation | Key Commands |
|------|---------------|--------------|
| Check service status | [Docker Commands](docker-commands.md) | `docker compose ps` |
| View application logs | [Logging & Debugging](logging-debugging.md) | `docker compose logs -f ghostfolio` |
| Access database | [Docker Commands](docker-commands.md) | `docker compose exec postgres psql -U ghostfolio` |
| Fix permissions | [Permissions Guide](permissions-guide.md) | `sudo chown -R $USER:docker /opt/ghostfolio/` |
| Monitor Redis | [Redis Management](redis-management.md) | `docker compose exec redis redis-cli monitor` |
| Edit configuration | [Editors & Tools](editors-tools.md) | `nano docker-compose.yml` |
| Performance tuning | [Advanced Optimization](advanced-optimization.md) | Various optimization techniques |

## 🛠️ Troubleshooting Index

### Container Issues
- **Container won't start** → [Docker Commands](docker-commands.md#container-health--debugging)
- **Permission denied errors** → [Permissions Guide](permissions-guide.md#troubleshooting-common-issues)
- **Resource constraints** → [Advanced Optimization](advanced-optimization.md#resource-monitoring)

### Database Problems
- **Connection issues** → [Docker Commands](docker-commands.md#database-container-access)
- **Performance problems** → [Advanced Optimization](advanced-optimization.md#database-performance-monitoring)
- **Data corruption** → [Logging & Debugging](logging-debugging.md#database-logs)

### Redis Issues
- **Cache problems** → [Redis Management](redis-management.md#troubleshooting)
- **Memory issues** → [Redis Management](redis-management.md#memory-optimization)
- **Configuration errors** → [Redis Management](redis-management.md#configuration-management)

### System Performance
- **High resource usage** → [Advanced Optimization](advanced-optimization.md#performance-optimization)
- **Slow response times** → [Logging & Debugging](logging-debugging.md#performance-issues)
- **Network problems** → [Advanced Optimization](advanced-optimization.md#network-optimization)

## 📖 Contributing to Documentation

These documentation files are designed to be:
- **Living documents** - Updated as the project evolves
- **User-friendly** - Written for various skill levels
- **Practical** - Focused on real-world scenarios
- **Comprehensive** - Covering common and advanced topics

### Editing Documentation
All documentation files are written in Markdown and can be edited with any text editor. See [Text Editors & Development Tools](editors-tools.md) for editor recommendations and setup.

### Feedback and Improvements
If you find gaps in the documentation or have suggestions for improvements, consider:
- Adding examples based on your experience
- Documenting solutions to problems you've encountered
- Expanding sections that need more detail
- Creating new sections for missing topics

## 🎯 Best Practices Summary

### Daily Operations
1. Monitor logs regularly using techniques from [Logging & Debugging](logging-debugging.md)
2. Check container health with commands from [Docker Commands](docker-commands.md)
3. Maintain proper file permissions as outlined in [Permissions Guide](permissions-guide.md)

### Weekly Maintenance
1. Review Redis performance using [Redis Management](redis-management.md) techniques
2. Check system resources following [Advanced Optimization](advanced-optimization.md) monitoring
3. Update documentation as your setup evolves

### Production Deployment
1. Implement security measures from [Advanced Optimization](advanced-optimization.md)
2. Set up comprehensive monitoring from [Logging & Debugging](logging-debugging.md)
3. Establish backup procedures from multiple guides

---

💡 **Pro Tip**: Bookmark this index and refer to specific sections as needed. Each guide is designed to be self-contained while cross-referencing related topics when helpful.

**Last Updated:** January 2025 | **Project Version:** 1.0.0
