#!/bin/bash

# EFL Server Test Script
# This script tests the Phoenix application server functionality

echo "=========================================="
echo "EFL Server Test Script"
echo "=========================================="
echo "Timestamp: $(date)"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test functions
test_passed() {
    echo -e "${GREEN}✓ PASSED${NC}: $1"
}

test_failed() {
    echo -e "${RED}✗ FAILED${NC}: $1"
}

test_warning() {
    echo -e "${YELLOW}⚠ WARNING${NC}: $1"
}

# Check if server is running
echo "1. Checking if server process is running..."
if pgrep -f "mix phx.server" > /dev/null; then
    test_passed "Server process is running"
    echo "   Process ID: $(pgrep -f 'mix phx.server')"
else
    test_failed "Server process is not running"
    echo "   Please start the server with: MIX_ENV=prod mix phx.server"
    exit 1
fi
echo ""

# Check if port 4000 is listening
echo "2. Checking if port 4000 is listening..."
if ss -tlnp | grep -q ":4000"; then
    test_passed "Port 4000 is listening"
else
    test_failed "Port 4000 is not listening"
    exit 1
fi
echo ""

# Test basic connectivity
echo "3. Testing basic HTTP connectivity..."
if wget -q --spider --timeout=10 http://localhost:4000 2>/dev/null; then
    test_passed "Server is accessible via HTTP"
else
    test_failed "Server is not accessible via HTTP"
    exit 1
fi
echo ""

# Test HTTP response codes
echo "4. Testing HTTP response codes..."

# Test root endpoint
echo "   Testing root endpoint (/)..."
HTTP_CODE=$(wget -q -O /dev/null -S --timeout=10 http://localhost:4000 2>&1 | grep "HTTP/" | awk '{print $2}')
if [ "$HTTP_CODE" = "200" ]; then
    test_passed "Root endpoint returns 200 OK"
else
    test_failed "Root endpoint returned $HTTP_CODE instead of 200"
fi

# Test dadi endpoint
echo "   Testing dadi endpoint (/dadi)..."
HTTP_CODE=$(wget -q -O /dev/null -S --timeout=10 http://localhost:4000/dadi 2>&1 | grep "HTTP/" | awk '{print $2}')
if [ "$HTTP_CODE" = "200" ]; then
    test_passed "Dadi endpoint returns 200 OK"
else
    test_failed "Dadi endpoint returned $HTTP_CODE instead of 200"
fi
echo ""

# Test response content
echo "5. Testing response content..."
echo "   Fetching root page content..."
CONTENT=$(wget -q -O - --timeout=10 http://localhost:4000 2>/dev/null)
if echo "$CONTENT" | grep -q "EFL\|Dadi\|Phoenix"; then
    test_passed "Page contains expected content"
else
    test_warning "Page content may not be as expected"
fi
echo ""

# Test database connectivity (indirectly through page load)
echo "6. Testing database connectivity..."
echo "   Checking if database queries are working..."
if echo "$CONTENT" | grep -q "dadi\|post\|content"; then
    test_passed "Database queries appear to be working"
else
    test_warning "Database connectivity unclear from page content"
fi
echo ""

# Test static assets
echo "7. Testing static assets..."
echo "   Testing favicon..."
if wget -q --spider --timeout=5 http://localhost:4000/favicon.ico 2>/dev/null; then
    test_passed "Favicon is accessible"
else
    test_warning "Favicon may not be accessible"
fi

echo "   Testing CSS assets..."
if wget -q --spider --timeout=5 http://localhost:4000/css/app.css 2>/dev/null; then
    test_passed "CSS assets are accessible"
else
    test_warning "CSS assets may not be accessible"
fi
echo ""

# Performance test
echo "8. Performance test..."
echo "   Testing response time..."
START_TIME=$(date +%s%N)
wget -q -O /dev/null --timeout=10 http://localhost:4000 2>/dev/null
END_TIME=$(date +%s%N)
RESPONSE_TIME=$(( (END_TIME - START_TIME) / 1000000 ))
if [ $RESPONSE_TIME -lt 1000 ]; then
    test_passed "Response time is good: ${RESPONSE_TIME}ms"
elif [ $RESPONSE_TIME -lt 3000 ]; then
    test_warning "Response time is acceptable: ${RESPONSE_TIME}ms"
else
    test_failed "Response time is slow: ${RESPONSE_TIME}ms"
fi
echo ""

# Test specific endpoints
echo "9. Testing specific endpoints..."
echo "   Testing /dadi/scratch endpoint..."
HTTP_CODE=$(wget -q -O /dev/null -S --timeout=10 http://localhost:4000/dadi/scratch 2>&1 | grep "HTTP/" | awk '{print $2}')
if [ "$HTTP_CODE" = "200" ]; then
    test_passed "Dadi scratch endpoint returns 200 OK"
else
    test_warning "Dadi scratch endpoint returned $HTTP_CODE"
fi
echo ""

# Memory and resource usage
echo "10. Checking resource usage..."
echo "    Memory usage:"
ps aux | grep -E "(elixir|beam)" | grep -v grep | awk '{print "   PID: " $2 ", CPU: " $3 "%, MEM: " $4 "%, CMD: " $11}'
echo ""

# Summary
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo "Server Status: $(pgrep -f 'mix phx.server' > /dev/null && echo 'RUNNING' || echo 'NOT RUNNING')"
echo "Port Status: $(ss -tlnp | grep -q ':4000' && echo 'LISTENING' || echo 'NOT LISTENING')"
echo "HTTP Access: $(wget -q --spider --timeout=5 http://localhost:4000 2>/dev/null && echo 'ACCESSIBLE' || echo 'NOT ACCESSIBLE')"
echo "Test completed at: $(date)"
echo "=========================================="

# Optional: Keep server running or stop it
echo ""
echo "Server is currently running. To stop it, run:"
echo "pkill -f 'mix phx.server'"
echo ""
echo "To restart the server, run:"
echo "MIX_ENV=prod mix phx.server"
