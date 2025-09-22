# Deployment Guide for EFL Docker Application

## 🎯 **Overview**

Your application files are **inside the Docker image**, not as separate files. To deploy to another server, you need to transfer the Docker image.

## 🚀 **Deployment Methods**

### **Method 1: Docker Registry (Recommended for Production)**

#### Step 1: Push to Registry
```bash
# Tag for your registry
docker tag efl-app:latest your-registry.com/efl-app:v1.0.0

# Push to registry
docker push your-registry.com/efl-app:v1.0.0
```

#### Step 2: Deploy on Target Server
```bash
# Pull and run on target server
docker pull your-registry.com/efl-app:v1.0.0
docker run -d --name efl-app -p 4000:4000 your-registry.com/efl-app:v1.0.0
```

**Popular Registries:**
- **Docker Hub**: `docker.io/yourusername/efl-app`
- **AWS ECR**: `123456789.dkr.ecr.us-west-2.amazonaws.com/efl-app`
- **Google GCR**: `gcr.io/your-project/efl-app`
- **Azure ACR**: `yourregistry.azurecr.io/efl-app`

### **Method 2: Save/Load TAR File (For Air-Gapped Environments)**

#### Step 1: Save Image to TAR
```bash
# Save the Docker image
docker-compose build
docker save -o efl-app-latest.tar efl-app:latest

# Or manually save
docker save -o efl-app.tar efl-app:latest
```

#### Step 2: Transfer and Load on Target Server
```bash
# Transfer the TAR file to target server
scp efl-app.tar user@target-server:/tmp/

# On target server, load the image
docker load -i /tmp/efl-app.tar

# Run the application
docker run -d --name efl-app -p 4000:4000 efl-app:latest
```

### **Method 3: Docker Compose (Recommended for Development)**

#### Step 1: Create Production Compose File
```yaml
# docker-compose.production.yml
version: '3.8'
services:
  efl-app:
    image: your-registry.com/efl-app:v1.0.0
    container_name: efl-app-prod
    restart: unless-stopped
    ports:
      - "4000:4000"
    environment:
      MIX_ENV: prod
      DATABASE_URL: mysql://user:pass@mysql:3306/efl_prod
      SECRET_KEY_BASE: your-secret-key-base
    depends_on:
      - mysql

  mysql:
    image: mysql:8.0
    container_name: efl-mysql-prod
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: your-mysql-password
      MYSQL_DATABASE: efl_prod
      MYSQL_USER: efl_user
      MYSQL_PASSWORD: your-mysql-password
    volumes:
      - mysql_data:/var/lib/mysql

volumes:
  mysql_data:
```

#### Step 2: Deploy
```bash
# On target server
docker-compose -f docker-compose.production.yml up -d
```

## 📁 **What to Commit to GitHub**

### **✅ DO Commit:**
- `Dockerfile` - Build instructions
- `docker-compose.yml` - Compose configuration
- `config/prod.secret.exs` - Production config template
- `DEPLOYMENT_GUIDE.md` - Documentation

### **❌ DON'T Commit:**
- `efl-app-*.tar` - Large binary files
- Docker images (they're in registry)
- `_build/` directory - Build artifacts
- `deps/` directory - Dependencies

### **📝 .gitignore Additions:**
```gitignore
# Docker images and build artifacts
efl-app-*.tar
_build/
deps/
.mix/

# Production secrets (use environment variables)
config/prod.secret.exs
env.prod
```

## 🔧 **Environment Configuration**

### **Required Environment Variables:**
```bash
# Database
DATABASE_URL=mysql://user:password@host:3306/database
MYSQL_ROOT_PASSWORD=your-secure-password
MYSQL_DATABASE=efl_prod
MYSQL_USER=efl_user
MYSQL_PASSWORD=your-mysql-password

# Application
MIX_ENV=prod
SECRET_KEY_BASE=your-secret-key-base-here
PORT=4000

# Optional: Registry
DOCKER_REGISTRY=your-registry.com
DOCKER_TAG=v1.0.0
```

## 🚀 **Quick Deployment Commands**

### **Build and Push to Registry:**
```bash
# Set registry
export DOCKER_REGISTRY=your-registry.com
export DOCKER_TAG=v1.0.0

# Build and push
docker-compose build
```

### **Deploy on Target Server:**
```bash
# Pull and run
docker pull your-registry.com/efl-app:v1.0.0
docker run -d --name efl-app -p 4000:4000 your-registry.com/efl-app:v1.0.0
```

### **Update Deployment:**
```bash
# Pull new version
docker pull your-registry.com/efl-app:v1.0.1

# Stop old container
docker stop efl-app && docker rm efl-app

# Run new version
docker run -d --name efl-app -p 4000:4000 your-registry.com/efl-app:v1.0.1
```

## 🔒 **Security Best Practices**

1. **Use Private Registry** for production images
2. **Never commit secrets** to GitHub
3. **Use environment variables** for configuration
4. **Scan images** for vulnerabilities
5. **Use specific tags** instead of `latest`

## 📊 **Image Size Optimization**

Current image: **2.54GB**
- **Runtime**: ~400MB (Elixir + Erlang)
- **Dependencies**: ~1.5GB (Phoenix, Ecto, etc.)
- **Application**: ~640MB (Your compiled code)

**To reduce size:**
- Use Alpine Linux base image
- Multi-stage build with minimal runtime
- Remove unused dependencies

## 🆘 **Troubleshooting**

### **Image Not Found:**
```bash
# Check if image exists
docker images | grep efl-app

# Rebuild if needed
docker-compose build
```

### **Registry Authentication:**
```bash
# Login to registry
docker login your-registry.com

# Check authentication
docker system info
```

### **Network Issues:**
```bash
# Test connectivity
docker run --rm efl-app:latest ping google.com

# Check DNS resolution
docker run --rm efl-app:latest nslookup your-database-host
```

## 📞 **Support**

For deployment issues:
1. Check Docker logs: `docker logs efl-app`
2. Verify environment variables
3. Test database connectivity
4. Check registry access

