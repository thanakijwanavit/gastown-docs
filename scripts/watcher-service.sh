#!/bin/bash
# watcher-service.sh - Service wrapper for gastowndocs watcher daemon
# Handles start/stop/restart with proper process management

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DAEMON_SCRIPT="$SCRIPT_DIR/watcher-daemon.sh"
PID_FILE="/tmp/gastowndocs-watcher.pid"
SERVICE_NAME="gastowndocs-watcher"

log() {
    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [SERVICE] $1"
}

start() {
    if [ -f "$PID_FILE" ]; then
        local pid
        pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            log "Watcher already running (PID: $pid)"
            return 0
        fi
        rm -f "$PID_FILE"
    fi
    
    log "Starting gastowndocs watcher daemon..."
    "$DAEMON_SCRIPT" start
    sleep 2
    
    if [ -f "$PID_FILE" ]; then
        local new_pid
        new_pid=$(cat "$PID_FILE")
        if kill -0 "$new_pid" 2>/dev/null; then
            log "Watcher started successfully (PID: $new_pid)"
            return 0
        fi
    fi
    
    log "ERROR: Failed to start watcher"
    return 1
}

stop() {
    if [ ! -f "$PID_FILE" ]; then
        log "Watcher not running"
        return 0
    fi
    
    local pid
    pid=$(cat "$PID_FILE")
    log "Stopping watcher (PID: $pid)..."
    
    if kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null || true
        sleep 1
        
        # Force kill if still running
        if kill -0 "$pid" 2>/dev/null; then
            kill -9 "$pid" 2>/dev/null || true
        fi
    fi
    
    rm -f "$PID_FILE"
    log "Watcher stopped"
}

restart() {
    stop
    sleep 1
    start
}

status() {
    "$DAEMON_SCRIPT" status
}

run_once() {
    log "Running single watcher cycle..."
    "$DAEMON_SCRIPT" run
}

case "${1:-}" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    status)
        status
        ;;
    run|once)
        run_once
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|run}"
        echo ""
        echo "  start    - Start the watcher daemon"
        echo "  stop     - Stop the watcher daemon"
        echo "  restart  - Restart the watcher daemon"
        echo "  status   - Show daemon status"
        echo "  run      - Run single check cycle"
        exit 1
        ;;
esac
