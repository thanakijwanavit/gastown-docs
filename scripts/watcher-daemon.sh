#!/bin/bash
# watcher-daemon.sh - Gas Town Watcher Daemon for gastowndocs
# Continuously monitors crew/polecat sessions and dispatches targeted healers
# Implements Kimi parity with gastown_manager
#
# Usage: ./watcher-daemon.sh {start|stop|run|status}

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GT_ROOT="${GT_ROOT:-$HOME/gt}"
RIG_NAME="gastowndocs"
RIG_DIR="$GT_ROOT/$RIG_NAME"
LOG_DIR="$RIG_DIR/logs"
STATE_DIR="$RIG_DIR/state"
PID_FILE="/tmp/gastowndocs-watcher.pid"

# Configuration
CHECK_INTERVAL=300       # 5 minutes between checks
IDLE_THRESHOLD=3600      # 1 hour = idle
STALE_THRESHOLD=7200     # 2 hours = stale (healer dispatch)
CRITICAL_THRESHOLD=14400 # 4 hours = critical (force restart)
COOLDOWN_PERIOD=1800     # 30 minutes between healer dispatches

# Messaging configuration
# Set INTERRUPT_MODE=1 to use nudges (immediate but interrupting)
# Default is mail-only (queued, non-interrupting)
INTERRUPT_MODE="${INTERRUPT_MODE:-0}"

# Healer configuration (Kimi parity)
HEALER_AGENT="${HEALER_AGENT:-kimigas}"
HEALER_DIR="$RIG_DIR/crew/healer"

# Ensure directories exist
mkdir -p "$LOG_DIR" "$STATE_DIR" "$HEALER_DIR/scripts" 2>/dev/null || true

# Logging functions
log() {
    local level="${1:-INFO}"
    shift
    local msg="$*"
    local ts
    ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    echo "[$ts] [WATCHER] [$level] $msg" | tee -a "$LOG_DIR/watcher-daemon.log"
    echo "{\"ts\":\"$ts\",\"level\":\"$level\",\"message\":\"$msg\"}" >> "$LOG_DIR/watcher-daemon.log.jsonl"
}

# ============================================================================
# SESSION MONITORING
# ============================================================================

# Check if tmux session exists
session_exists() {
    tmux has-session -t "$1" 2>/dev/null
}

# Get session age in seconds (-1 if not found)
session_age() {
    local name="$1"
    local created
    created=$(tmux list-sessions -F "#{session_name}:#{session_created}" 2>/dev/null | grep "^${name}:" | cut -d: -f2)
    if [ -n "$created" ]; then
        echo $(($(date +%s) - created))
    else
        echo "-1"
    fi
}

# Get idle time from tmux (milliseconds of no input)
session_idle_ms() {
    local name="$1"
    tmux display-message -t "$name" -p '#{session_activity}' 2>/dev/null || echo "0"
}

# Calculate idle seconds from last activity
session_idle_seconds() {
    local name="$1"
    local last_activity
    last_activity=$(tmux display-message -t "$name" -p '#{session_activity}' 2>/dev/null || echo "0")
    if [ "$last_activity" != "0" ] && [ -n "$last_activity" ]; then
        local now
        now=$(date +%s)
        echo $((now - last_activity))
    else
        echo "0"
    fi
}

# Get pane content for analysis
get_pane_content() {
    local name="$1"
    local lines="${2:-50}"
    tmux capture-pane -t "$name" -p 2>/dev/null | tail -n "$lines" || echo ""
}

# ============================================================================
# SESSION CLASSIFICATION
# ============================================================================

# Get all gastowndocs sessions
get_rig_sessions() {
    tmux list-sessions -F "#{session_name}" 2>/dev/null | grep "^gt-${RIG_NAME}" || true
}

# Classify session type
classify_session() {
    local name="$1"
    if echo "$name" | grep -q "crew"; then
        echo "crew"
    elif echo "$name" | grep -q "polecat"; then
        echo "polecat"
    elif echo "$name" | grep -q "witness"; then
        echo "witness"
    elif echo "$name" | grep -q "refinery"; then
        echo "refinery"
    else
        echo "unknown"
    fi
}

# Extract agent name from session
get_agent_name() {
    local name="$1"
    # Format: gt-gastowndocs-crew-nic or gt-gastowndocs-polecats-ace
    echo "$name" | sed "s/gt-${RIG_NAME}-//;s/polecats\//polecat-/"
}

# ============================================================================
# HEALER DISPATCH
# ============================================================================

# Check if healer is on cooldown for this session
is_healer_on_cooldown() {
    local session="$1"
    local cooldown_file="$STATE_DIR/healer-cooldown-${session}"
    
    if [ -f "$cooldown_file" ]; then
        local last_dispatch
        last_dispatch=$(cat "$cooldown_file")
        local now
        now=$(date +%s)
        local elapsed=$((now - last_dispatch))
        if [ "$elapsed" -lt "$COOLDOWN_PERIOD" ]; then
            echo "$((COOLDOWN_PERIOD - elapsed))"
            return 0
        fi
    fi
    return 1
}

# Set healer cooldown
set_healer_cooldown() {
    local session="$1"
    local cooldown_file="$STATE_DIR/healer-cooldown-${session}"
    date +%s > "$cooldown_file"
}

# Dispatch targeted healer for idle session
dispatch_healer() {
    local session="$1"
    local reason="$2"
    local session_age="$3"
    local agent_name
    agent_name=$(get_agent_name "$session")
    
    log INFO "Dispatching healer for $session (reason: $reason, age: ${session_age}s)"
    
    # Check cooldown
    local cooldown_remaining
    if cooldown_remaining=$(is_healer_on_cooldown "$session"); then
        log WARN "Healer on cooldown for $session (${cooldown_remaining}s remaining)"
        return 1
    fi
    
    # Create healer dispatch marker
    local marker_file="$STATE_DIR/healer-dispatch-${session}-$(date +%s)"
    cat > "$marker_file" << EOF
{
  "session": "$session",
  "agent": "$agent_name",
  "reason": "$reason",
  "session_age": $session_age,
  "dispatched_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "healer_agent": "$HEALER_AGENT"
}
EOF
    
    # Set cooldown
    set_healer_cooldown "$session"
    
    # Log dispatch
    log INFO "Healer marker created: $marker_file"
    
    # Queue mail notification (non-interrupting)
    if command -v gt >/dev/null 2>&1; then
        gt mail send "$agent_name" -s "Watcher: Idle Session Detected" -m "Your session $session has been idle for ${session_age}s.

Reason: $reason
Severity: $reason

Action Required:
1. Run: gt prime && bd prime
2. Check: gt hook
3. Resume work or run: gt handoff

This is an automated message from the gastowndocs watcher daemon.
Queued messages do not interrupt your session." 2>/dev/null || true
        log INFO "Mail queued for $agent_name"
    fi
    
    # Only nudge (interrupt) if CRITICAL and INTERRUPT_MODE is enabled
    if [ "$INTERRUPT_MODE" = "1" ] && [ "$reason" = "critical_idle" ]; then
        local nudge_msg="CRITICAL: $agent_name session ${session_age}s old. Run gt prime && bd prime. Check gt hook. See GASTOWN_AGENT_PRIMER.md"
        if command -v gt >/dev/null 2>&1; then
            local nudge_target
            nudge_target=$(session_to_nudge_target "$session")
            if [ -n "$nudge_target" ]; then
                gt nudge "$nudge_target" "$nudge_msg" 2>/dev/null || log WARN "Nudge failed for $nudge_target"
                log INFO "Nudge sent to $nudge_target (CRITICAL + INTERRUPT_MODE)"
            fi
        fi
    fi
    
    return 0
}

# Map tmux session to gt nudge target
session_to_nudge_target() {
    local session="$1"
    case "$session" in
        gt-gastowndocs-witness) echo "gastowndocs/witness" ;;
        gt-gastowndocs-refinery) echo "gastowndocs/refinery" ;;
        gt-gastowndocs-crew-*) 
            local crew_name
            crew_name=$(echo "$session" | sed 's/gt-gastowndocs-crew-//')
            echo "gastowndocs/crew/$crew_name"
            ;;
        gt-gastowndocs-polecats-*)
            local polecat_name
            polecat_name=$(echo "$session" | sed 's/gt-gastowndocs-polecats-//')
            echo "gastowndocs/polecats/$polecat_name"
            ;;
        *) echo "" ;;
    esac
}

# ============================================================================
# MAIN MONITORING CYCLE
# ============================================================================

run_cycle() {
    log INFO "=== Watcher cycle starting ==="
    
    local sessions
    sessions=$(get_rig_sessions)
    
    if [ -z "$sessions" ]; then
        log INFO "No active gastowndocs sessions found"
        return 0
    fi
    
    local session_count
    session_count=$(echo "$sessions" | wc -l)
    log INFO "Found $session_count active session(s)"
    
    local idle_count=0
    local healer_dispatched=0
    
    for session in $sessions; do
        local age
        age=$(session_age "$session")
        local type
        type=$(classify_session "$session")
        local agent
        agent=$(get_agent_name "$session")
        
        log DEBUG "Checking $session (type: $type, age: ${age}s)"
        
        # Skip if session is young
        if [ "$age" -lt "$IDLE_THRESHOLD" ]; then
            continue
        fi
        
        ((idle_count++)) || true
        
        # Determine action based on age
        if [ "$age" -gt "$CRITICAL_THRESHOLD" ]; then
            log ERROR "CRITICAL: $session idle for ${age}s - force handoff recommended"
            dispatch_healer "$session" "critical_idle" "$age"
            healer_dispatched=$((healer_dispatched + 1))
        elif [ "$age" -gt "$STALE_THRESHOLD" ]; then
            log WARN "STALE: $session idle for ${age}s"
            dispatch_healer "$session" "stale_session" "$age"
            healer_dispatched=$((healer_dispatched + 1))
        elif [ "$age" -gt "$IDLE_THRESHOLD" ]; then
            log INFO "IDLE: $session idle for ${age}s - sending notification"
            # Queue mail notification (non-interrupting)
            if command -v gt >/dev/null 2>&1; then
                gt mail send "$agent" -s "Watcher: Idle Session Reminder" -m "Your session $session has been idle for ${age}s.

This is a friendly reminder to check your session.

Actions:
1. Run: gt prime && bd prime
2. Check: gt hook
3. Resume work or run: gt handoff

Queued messages do not interrupt your session." 2>/dev/null || true
            fi
            # Only nudge if INTERRUPT_MODE is enabled
            if [ "$INTERRUPT_MODE" = "1" ]; then
                local nudge_target
                nudge_target=$(session_to_nudge_target "$session")
                if [ -n "$nudge_target" ] && command -v gt >/dev/null 2>&1; then
                    gt nudge "$nudge_target" "Watcher: $agent session ${age}s old. Run gt prime && bd prime. Check gt hook." 2>/dev/null || true
                fi
            fi
        fi
    done
    
    # Update state
    cat > "$STATE_DIR/watcher-state.json" << EOF
{
  "last_check": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "sessions_checked": $session_count,
  "idle_found": $idle_count,
  "healers_dispatched": $healer_dispatched,
  "check_interval": $CHECK_INTERVAL,
  "thresholds": {
    "idle": $IDLE_THRESHOLD,
    "stale": $STALE_THRESHOLD,
    "critical": $CRITICAL_THRESHOLD,
    "cooldown": $COOLDOWN_PERIOD
  }
}
EOF
    
    log INFO "=== Cycle complete: $idle_count idle, $healer_dispatched healers dispatched ==="
}

# ============================================================================
# DAEMON MODES
# ============================================================================

run_daemon() {
    log INFO "Watcher daemon starting (interval=${CHECK_INTERVAL}s, healer=$HEALER_AGENT)"
    echo $$ > "$PID_FILE"
    
    # Write PID file with additional metadata
    cat > "$STATE_DIR/watcher-pid.json" << EOF
{
  "pid": $$,
  "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "agent": "$HEALER_AGENT",
  "check_interval": $CHECK_INTERVAL
}
EOF
    
    while true; do
        run_cycle
        log INFO "Sleeping ${CHECK_INTERVAL}s..."
        sleep "$CHECK_INTERVAL"
    done
}

stop_daemon() {
    if [ -f "$PID_FILE" ]; then
        local pid
        pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null
            log INFO "Daemon stopped (PID: $pid)"
        else
            log WARN "Daemon not running (stale PID file)"
        fi
        rm -f "$PID_FILE"
    else
        log WARN "No PID file found"
    fi
    
    # Update state
    if [ -f "$STATE_DIR/watcher-pid.json" ]; then
        rm -f "$STATE_DIR/watcher-pid.json"
    fi
}

show_status() {
    echo "=== gastowndocs Watcher Status ==="
    echo ""
    echo "Mode: $( [ "$INTERRUPT_MODE" = "1" ] && echo "INTERRUPT (nudges enabled)" || echo "QUEUED (mail only)" )"
    
    # Daemon status
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "Daemon: ✅ Running (PID: $(cat "$PID_FILE"))"
    else
        echo "Daemon: ⏹️  Stopped"
        [ -f "$PID_FILE" ] && rm -f "$PID_FILE"
    fi
    echo ""
    
    # Active sessions
    echo "Active gastowndocs sessions:"
    local sessions
    sessions=$(get_rig_sessions)
    if [ -z "$sessions" ]; then
        echo "  (none)"
    else
        for session in $sessions; do
            local age
            age=$(session_age "$session")
            local type
            type=$(classify_session "$session")
            local status_emoji="✅"
            if [ "$age" -gt "$CRITICAL_THRESHOLD" ]; then
                status_emoji="🔴"
            elif [ "$age" -gt "$STALE_THRESHOLD" ]; then
                status_emoji="🟡"
            elif [ "$age" -gt "$IDLE_THRESHOLD" ]; then
                status_emoji="🟠"
            fi
            printf "  %s %-40s (%s, %ss)\n" "$status_emoji" "$session" "$type" "$age"
        done
    fi
    echo ""
    
    # Last check
    if [ -f "$STATE_DIR/watcher-state.json" ]; then
        echo "Last state:"
        cat "$STATE_DIR/watcher-state.json"
        echo ""
    fi
    
    # Healer cooldowns
    local cooldowns
    cooldowns=$(ls "$STATE_DIR"/healer-cooldown-* 2>/dev/null || true)
    if [ -n "$cooldowns" ]; then
        echo "Active healer cooldowns:"
        for f in $cooldowns; do
            local session_name
            session_name=$(basename "$f" | sed 's/healer-cooldown-//')
            local last_dispatch
            last_dispatch=$(cat "$f")
            local now
            now=$(date +%s)
            local elapsed=$((now - last_dispatch))
            local remaining=$((COOLDOWN_PERIOD - elapsed))
            if [ "$remaining" -gt 0 ]; then
                printf "  %s: %ss remaining\n" "$session_name" "$remaining"
            fi
        done
    fi
}

# ============================================================================
# MAIN
# ============================================================================

case "${1:-run}" in
    start)
        if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
            log WARN "Daemon already running (PID: $(cat "$PID_FILE"))"
            exit 1
        fi
        nohup "$SCRIPT_DIR/watcher-daemon.sh" daemon >> "$LOG_DIR/watcher-daemon.log" 2>&1 &
        sleep 1
        if [ -f "$PID_FILE" ]; then
            echo "Watcher daemon started (PID: $(cat "$PID_FILE"))"
        else
            echo $! > "$PID_FILE"
            echo "Watcher daemon started (PID: $!)"
        fi
        ;;
    stop)
        stop_daemon
        ;;
    daemon)
        run_daemon
        ;;
    run)
        run_cycle
        ;;
    status)
        show_status
        ;;
    *)
        echo "Usage: $0 {start|stop|run|status|daemon}"
        echo ""
        echo "  start   - Start watcher daemon"
        echo "  stop    - Stop watcher daemon"
        echo "  run     - Run single check cycle"
        echo "  status  - Show current status"
        echo "  daemon  - Run in daemon mode (internal use)"
        echo ""
        echo "Configuration:"
        echo "  CHECK_INTERVAL=${CHECK_INTERVAL}s"
        echo "  IDLE_THRESHOLD=${IDLE_THRESHOLD}s (1 hour)"
        echo "  STALE_THRESHOLD=${STALE_THRESHOLD}s (2 hours)"
        echo "  CRITICAL_THRESHOLD=${CRITICAL_THRESHOLD}s (4 hours)"
        echo "  COOLDOWN_PERIOD=${COOLDOWN_PERIOD}s (30 minutes)"
        echo "  INTERRUPT_MODE=${INTERRUPT_MODE} (0=mail only, 1=enable nudges)"
        echo ""
        echo "Note: By default, notifications are queued via mail (non-interrupting)."
        echo "      Set INTERRUPT_MODE=1 to enable nudges (immediate but interrupting)."
        exit 1
        ;;
esac
