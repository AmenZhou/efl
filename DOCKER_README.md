# EFL Application - Docker Deployment

This document describes how to deploy the EFL Elixir application using Docker.

## Server Resources

- **RAM**: 1.9GB total, ~980MB available
- **CPU**: 1 core
- **Disk**: 19GB total, ~6.8GB available
- **Docker**: Installed and configured

## Architecture

The application uses a multi-container setup:

1. **MySQL 8.0** - Database with utf8mb4 charset
2. **Elixir 1.17.3** - Phoenix application
3. **phpMyAdmin** - Database management (optional)

## Files Created

- `Dockerfile` - Elixir application container
- `docker-compose.prod.yml` - Production orchestration
- `env.prod` - Environment variables
- `deploy.sh` - Deployment script
- `DOCKER_README.md` - This documentation

## Quick Start

1. **Configure environment variables:**
   ```bash
   # Edit env.prod with your settings
   nano env.prod
   ```

2. **Deploy the application:**
   ```bash
   ./deploy.sh
   ```

3. **Access the application:**
   - Application: http://localhost:4000
   - phpMyAdmin: http://localhost:8080

## Manual Commands

### Start all services
```bash
docker-compose -f docker-compose.prod.yml up -d
```

### View logs
```bash
docker-compose -f docker-compose.prod.yml logs -f
```

### Run database migration
```bash
docker-compose -f docker-compose.prod.yml run --rm efl-app mix ecto.migrate
```

### Stop all services
```bash
docker-compose -f docker-compose.prod.yml down
```

### Rebuild application
```bash
docker-compose -f docker-compose.prod.yml build --no-cache efl-app
```

## Resource Limits

The containers are configured with memory limits suitable for the server:

- **MySQL**: 512MB limit, 256MB reservation
- **EFL App**: 768MB limit, 512MB reservation  
- **phpMyAdmin**: 128MB limit, 64MB reservation

## Database Migration

The charset migration (`20241206000000_update_content_column_charset.exs`) will be automatically applied when the application starts.

## Troubleshooting

### Check container status
```bash
docker-compose -f docker-compose.prod.yml ps
```

### View specific service logs
```bash
docker-compose -f docker-compose.prod.yml logs efl-app
docker-compose -f docker-compose.prod.yml logs mysql
```

### Access application shell
```bash
docker-compose -f docker-compose.prod.yml exec efl-app bash
```

### Check database connection
```bash
docker-compose -f docker-compose.prod.yml exec mysql mysql -u root -p
```

## Security Notes

- Change default passwords in `env.prod`
- Use strong SECRET_KEY_BASE
- Consider using Docker secrets for production
- Restrict network access as needed

## Backup

Database backups are stored in the `mysql_data` Docker volume. To backup:

```bash
docker-compose -f docker-compose.prod.yml exec mysql mysqldump -u root -p classification_utility_prod > backup_$(date +%Y%m%d_%H%M%S).sql
```



