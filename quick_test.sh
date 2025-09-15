#!/bin/bash

# Quick EFL Server Test Script
# Simple wget-based tests for quick verification

echo "Quick EFL Server Test"
echo "===================="
echo "Timestamp: $(date)"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Test 1: Basic connectivity
echo "1. Testing basic connectivity..."
if wget -q --spider --timeout=10 http://localhost:4000 2>/dev/null; then
    echo -e "${GREEN}✓ PASSED${NC}: Server is accessible"
else
    echo -e "${RED}✗ FAILED${NC}: Server is not accessible"
    exit 1
fi

# Test 2: Root endpoint
echo "2. Testing root endpoint..."
HTTP_CODE=$(wget -q -O /dev/null -S --timeout=10 http://localhost:4000 2>&1 | grep "HTTP/" | awk '{print $2}')
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ PASSED${NC}: Root endpoint returns 200 OK"
else
    echo -e "${RED}✗ FAILED${NC}: Root endpoint returned $HTTP_CODE"
fi

# Test 3: Dadi scratch endpoint
echo "3. Testing dadi scratch endpoint..."
HTTP_CODE=$(wget -q -O /dev/null -S --timeout=10 http://localhost:4000/dadi/scratch 2>&1 | grep "HTTP/" | awk '{print $2}')
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ PASSED${NC}: Dadi scratch endpoint returns 200 OK"
else
    echo -e "${RED}✗ FAILED${NC}: Dadi scratch endpoint returned $HTTP_CODE"
fi

# Test 4: Response time
echo "4. Testing response time..."
START_TIME=$(date +%s%N)
wget -q -O /dev/null --timeout=10 http://localhost:4000 2>/dev/null
END_TIME=$(date +%s%N)
RESPONSE_TIME=$(( (END_TIME - START_TIME) / 1000000 ))
echo "Response time: ${RESPONSE_TIME}ms"

# Test 5: Content check
echo "5. Testing content..."
CONTENT=$(wget -q -O - --timeout=10 http://localhost:4000 2>/dev/null)
if echo "$CONTENT" | grep -q "dadi\|post\|content"; then
    echo -e "${GREEN}✓ PASSED${NC}: Page contains expected content"
else
    echo -e "${RED}✗ FAILED${NC}: Page content not as expected"
fi

echo ""
echo "Quick test completed at: $(date)"
