# Docker HTTP Request Troubleshooting Guide

## Problem
HTTP requests work in production but fail in Docker development environment.

## Root Causes

### 1. Missing Network Dependencies
- Alpine Linux containers may lack SSL certificates
- Missing curl/wget for HTTP testing
- Incomplete network stack

### 2. Proxy System Dependencies
- Production uses proxy rotation (Efl.MyHttp)
- Development proxy system not configured
- Proxy API keys not available in dev

### 3. Network Configuration
- Docker networking differences
- DNS resolution issues
- Firewall/proxy blocking

## Solutions Implemented

### 1. Enhanced Dockerfile
```dockerfile
# Added missing network dependencies
RUN apk add --no-cache \
    build-base \
    git \
    mysql-client \
    openssl \
    ncurses-libs \
    wget \
    curl \
    ca-certificates \
    libssl1.1
```

### 2. Updated docker-compose.yml
```yaml
environment:
  - HTTP_PROXY=
  - HTTPS_PROXY=
  - NO_PROXY=localhost,127.0.0.1,mysql
network_mode: "bridge"
dns:
  - 8.8.8.8
  - 8.8.4.4
```

### 3. Development HTTP Client
- Created `Efl.DevHttp` - simple HTTP client without proxy requirements
- Created `Efl.DevMyHttp` - development version of MyHttp
- Environment-based switching in parsers

### 4. Configuration Files
- `config/dev_http.exs` - development HTTP configuration
- Updated `config/dev.exs` to import dev HTTP config

## Testing

### 1. Test HTTP Connectivity
```bash
# Run the test script
elixir test_http_dev.exs
```

### 2. Test Inside Container
```bash
# Build and run container
docker-compose up --build

# Test inside container
docker exec -it efl-app elixir test_http_dev.exs
```

### 3. Test Application HTTP Requests
```bash
# Test the application's HTTP requests
docker exec -it efl-app mix run -e "Efl.DevMyHttp.request(\"https://httpbin.org/get\")"
```

## Debugging Steps

### 1. Check Network Connectivity
```bash
# Inside container
ping google.com
nslookup google.com
curl -I https://google.com
```

### 2. Check DNS Resolution
```bash
# Test DNS
nslookup c.dadi360.com
dig c.dadi360.com
```

### 3. Check SSL Certificates
```bash
# Test SSL
openssl s_client -connect c.dadi360.com:443 -servername c.dadi360.com
```

### 4. Check Application Logs
```bash
# View application logs
docker logs efl-app
docker logs efl-app 2>&1 | grep -i "http\|error\|fail"
```

## Environment Variables

### Required for Development
```bash
MIX_ENV=dev
HTTP_PROXY=
HTTPS_PROXY=
NO_PROXY=localhost,127.0.0.1,mysql
```

### Optional for Production-like Testing
```bash
PROXY_ROTATOR_API_KEY=your_api_key
PROXY_ROTATOR_ENABLED=true
```

## Common Issues and Fixes

### Issue: "Connection refused" or "Network unreachable"
**Fix**: Check Docker network configuration and DNS settings

### Issue: "SSL certificate verify failed"
**Fix**: Ensure ca-certificates package is installed

### Issue: "Timeout" errors
**Fix**: Increase timeout values in development config

### Issue: "Proxy connection failed"
**Fix**: Use DevMyHttp instead of MyHttp in development

### Issue: "DNS resolution failed"
**Fix**: Check DNS configuration in docker-compose.yml

## Monitoring

### Check HTTP Request Success
```elixir
# In IEx
Efl.DevMyHttp.request("https://httpbin.org/get")
```

### Monitor Application Logs
```bash
# Follow logs
docker logs -f efl-app
```

### Test Specific URLs
```elixir
# Test target website
Efl.DevMyHttp.request("http://c.dadi360.com/c/forums/show/80/1.page")
```

## Production vs Development Differences

| Aspect | Production | Development |
|--------|------------|-------------|
| HTTP Client | Efl.MyHttp (with proxies) | Efl.DevMyHttp (direct) |
| Proxy System | Enabled | Disabled |
| Timeout | 120s | 30s |
| Retries | 50 | 10 |
| Validation | Strict proxy validation | Simple content validation |

## Next Steps

1. **Test the fixes**: Run `elixir test_http_dev.exs`
2. **Rebuild container**: `docker-compose up --build`
3. **Verify HTTP requests work**: Check application logs
4. **Test scraping**: Run the actual scraping process
5. **Monitor performance**: Ensure requests complete successfully
