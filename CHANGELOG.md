# Changelog

All notable changes to the EFL (Elixir Phoenix) project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] - 2024-12-06

### Added
- **Docker Configuration (Development Only)**
  - Lightweight Docker setup for development and testing environments
  - Single-stage Dockerfile using `elixir:1.17-alpine` base image
  - Docker Compose configuration with MySQL 8.0 and application services
  - Resource limits and reservations for both MySQL and application containers
  - Health checks for MySQL and application containers
  - Non-root user security configuration in Docker container
  - **Note**: Docker setup intended for development only; production uses native deployment

- **Database Optimization**
  - MySQL 8.0 configuration tuned for low-resource environments
  - Optimized MySQL parameters: `innodb-buffer-pool-size=32M`, `max-connections=10`
  - UTF-8 support with `utf8mb4` character set and `utf8mb4_unicode_ci` collation
  - Disabled performance schema and native AIO for resource efficiency

- **Tool Version Management**
  - `.tool-version` file documenting active tool versions
  - Elixir 1.17.3, Erlang 27, Docker 27.1.1, Phoenix 1.7.0

- **Testing Infrastructure**
  - Standalone test runner that works without database connections
  - Database-independent test approach to avoid MySQL connection pool exhaustion
  - Comprehensive test coverage for basic functionality validation

### Changed
- **Elixir/Phoenix Upgrade**
  - Upgraded from Elixir ~1.4 to ~1.17
  - Upgraded Phoenix from ~1.5.0 to ~1.7.0
  - Updated Phoenix HTML from ~2.14 to ~4.0
  - Updated all dependencies to compatible versions
  - Replaced deprecated `Mix.Config` with `Config` module (warnings remain for future cleanup)

- **Database Configuration**
  - Migrated from `Ecto.Adapters.MySQL` to `Ecto.Adapters.MyXQL`
  - Updated database hostname from `localhost` to `mysql` for Docker networking
  - Optimized test database configuration with reduced pool size and queue settings

- **Dependency Updates**
  - Updated `hackney` from ~1.18 to ~1.20
  - Updated `poison` from ~4.0 to ~5.0
  - Added `swoosh` for email functionality
  - Added `tesla` for HTTP client functionality
  - Added `multipart` and `plug` dependencies

- **Docker Configuration (Development Only)**
  - Removed precompilation approach in favor of runtime compilation
  - Optimized Dockerfile layer order for better caching
  - Added proper permissions management for non-root user
  - Configured `MIX_HOME` environment variable for mix cache access
  - **Note**: Docker configuration optimized for development; production uses native deployment

### Removed
- **Precompilation Infrastructure**
  - Removed `Dockerfile.precompiled`
  - Removed `docker-compose.precompiled.yml`
  - Removed `PRECOMPILED_DEPLOYMENT.md`
  - Removed `build-precompiled.sh`
  - Removed `deploy-precompiled.sh`
  - Removed `test-precompiled.sh`
  - Removed `dev-cached.sh`
  - Removed `releases` function from `mix.exs`

- **Redundant Database Initialization**
  - Removed `mysql-init/01-init.sql` (redundant with Ecto migrations)
  - Removed init file mount from Docker Compose configuration
  - Eliminated schema duplication between init file and migrations

- **Unnecessary Test Scripts**
  - Removed `test_runner.sh` (caused MySQL connection issues)
  - Removed `run_unit_tests.sh` (still triggered database connections)
  - Removed `run_standalone_tests.sh` (replaced with inline testing)
  - Removed all test files that required database connections
  - Cleaned up test directory structure

- **Deprecated Files**
  - Removed `push-to-registry.sh` (outdated deployment script)

### Fixed
- **Database Connection Issues**
  - Fixed MySQL connection pool exhaustion in test environment
  - Resolved "Too many connections" errors during testing
  - Fixed database hostname configuration for Docker networking
  - Resolved schema mismatch issues between init file and migrations

- **Docker Build Issues**
  - Fixed dependency installation and compilation in Docker container
  - Resolved permission issues for non-root user access to dependencies
  - Fixed Elixir version compatibility issues
  - Resolved MySQL container health check failures

- **Migration Compatibility**
  - Updated `timestamps` to `timestamps()` in all migration files
  - Fixed migration execution order and dependencies
  - Resolved table creation conflicts between init file and migrations

### Security
- **Docker Security**
  - Implemented non-root user execution in Docker container
  - Configured proper file permissions and ownership
  - Isolated application dependencies and cache directories

### Performance
- **Resource Optimization**
  - Optimized MySQL configuration for 2GB RAM constraint
  - Reduced database connection pool size for test environment
  - Implemented lightweight testing approach without database connections
  - Optimized Docker image size with Alpine Linux base

### Infrastructure
- **Docker Compose**
  - Configured service dependencies and health checks
  - Implemented proper service startup order
  - Added resource limits and reservations
  - Configured volume persistence for MySQL data

- **Database Management**
  - Migrated to Ecto migrations as single source of truth for schema
  - Implemented proper UTF-8 support across all database operations
  - Configured database for Docker networking

## [Previous Versions]

### Legacy Configuration (Pre-2024-12-06)
- Original Elixir 1.4/Phoenix 1.5.0 setup
- MySQL with manual schema management
- Precompilation-based deployment approach
- Local development without Docker containerization

---

## Migration Notes

### For Developers
1. **Database Setup**: Run `docker-compose up -d` and `docker-compose exec app mix ecto.migrate`
2. **Testing**: Use the standalone test approach to avoid database connection issues
3. **Development**: Application runs on `http://localhost:4000` in Docker environment
4. **Dependencies**: All dependencies are automatically installed and compiled in Docker

### For Production Deployment
1. **Resource Requirements**: Minimum 2GB RAM, 1 core CPU, 15GB disk
2. **Database**: MySQL 8.0 with optimized configuration for low-resource environments
3. **Application**: Elixir 1.17.3 with Phoenix 1.7.0
4. **Containerization**: Docker with Alpine Linux base for minimal resource usage

### Breaking Changes
- **Database Adapter**: Changed from MySQL to MyXQL adapter
- **Configuration**: Updated from `Mix.Config` to `Config` module (warnings present)
- **Docker**: Complete migration to Docker-based development and deployment
- **Testing**: Moved from database-dependent to database-independent testing approach

---

## Contributors
- Development and optimization work completed on 2024-12-06
- Focus on resource-constrained production environment optimization
- Docker containerization and lightweight deployment strategy
