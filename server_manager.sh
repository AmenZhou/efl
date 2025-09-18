#!/bin/bash

# EFL Server Management Script
# Usage: ./server_manager.sh [start|stop|restart|status|logs]

PID_FILE="/tmp/efl_server.pid"
LOG_FILE="/root/apps/efl/server.log"
APP_DIR="/root/apps/efl"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[EFL Server]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[EFL Server]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[EFL Server]${NC} $1"
}

print_error() {
    echo -e "${RED}[EFL Server]${NC} $1"
}

# Function to check if server is running
is_running() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            return 0
        else
            rm -f "$PID_FILE"
            return 1
        fi
    else
        return 1
    fi
}

# Function to start the server
start_server() {
    print_status "Starting EFL server..."
    
    if is_running; then
        print_warning "Server is already running (PID: $(cat $PID_FILE))"
        return 1
    fi
    
    cd "$APP_DIR" || {
        print_error "Failed to change to app directory: $APP_DIR"
        exit 1
    }
    
    # Start server in background
    MIX_ENV=prod nohup mix phx.server > "$LOG_FILE" 2>&1 &
    local pid=$!
    
    # Save PID
    echo "$pid" > "$PID_FILE"
    
    # Wait a moment and check if it started successfully
    sleep 3
    if is_running; then
        print_success "Server started successfully (PID: $pid)"
        print_status "Server is running on http://localhost:4000"
        print_status "Logs are being written to: $LOG_FILE"
    else
        print_error "Failed to start server. Check logs: $LOG_FILE"
        rm -f "$PID_FILE"
        return 1
    fi
}

# Function to stop the server
stop_server() {
    print_status "Stopping EFL server..."
    
    if ! is_running; then
        print_warning "Server is not running"
        return 1
    fi
    
    local pid=$(cat "$PID_FILE")
    print_status "Stopping server (PID: $pid)..."
    
    # Try graceful shutdown first
    kill -TERM "$pid" 2>/dev/null
    
    # Wait for graceful shutdown
    local count=0
    while [ $count -lt 10 ] && is_running; do
        sleep 1
        count=$((count + 1))
    done
    
    # Force kill if still running
    if is_running; then
        print_warning "Graceful shutdown failed, forcing stop..."
        kill -KILL "$pid" 2>/dev/null
        sleep 1
    fi
    
    if is_running; then
        print_error "Failed to stop server"
        return 1
    else
        print_success "Server stopped successfully"
        rm -f "$PID_FILE"
    fi
}

# Function to restart the server
restart_server() {
    print_status "Restarting EFL server..."
    stop_server
    sleep 2
    start_server
}

# Function to show server status
show_status() {
    print_status "EFL Server Status:"
    echo "=================="
    
    if is_running; then
        local pid=$(cat "$PID_FILE")
        print_success "Server is RUNNING (PID: $pid)"
        print_status "URL: http://localhost:4000"
        print_status "Log file: $LOG_FILE"
        
        # Show memory usage
        local memory=$(ps -o rss= -p "$pid" 2>/dev/null | awk '{print $1/1024 " MB"}')
        print_status "Memory usage: $memory"
        
        # Show uptime
        local start_time=$(ps -o lstart= -p "$pid" 2>/dev/null)
        print_status "Started: $start_time"
    else
        print_error "Server is NOT running"
    fi
}

# Function to show logs
show_logs() {
    if [ -f "$LOG_FILE" ]; then
        print_status "Showing server logs (last 50 lines):"
        echo "=========================================="
        tail -n 50 "$LOG_FILE"
    else
        print_warning "No log file found: $LOG_FILE"
    fi
}

# Function to show help
show_help() {
    echo "EFL Server Management Script"
    echo "==========================="
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  start    - Start the server in background"
    echo "  stop     - Stop the running server"
    echo "  restart  - Restart the server"
    echo "  status   - Show server status"
    echo "  logs     - Show recent logs"
    echo "  help     - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start"
    echo "  $0 restart"
    echo "  $0 status"
}

# Main script logic
case "${1:-help}" in
    start)
        start_server
        ;;
    stop)
        stop_server
        ;;
    restart)
        restart_server
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
