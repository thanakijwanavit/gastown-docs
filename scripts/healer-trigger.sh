#!/bin/bash
# healer-trigger.sh - Targeted Healer Dispatch for gastowndocs
# Triggered by watcher daemon to heal idle/stuck sessions
# Maintains cooldowns and marker verification

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GT_ROOT="${GT_ROOT:-$HOME/gt}"
RIG_NAME="gastowndocs"
RIG_DIR="$GT_ROOT/$RIG_NAME"
LOG_DIR="$RIG_DIR/logs"
STATE_DIR="$RIG_DIR/state"

# Configuration
HEALER_AGENT="${HEALER_AGENT:-kimigas}"
COOLDOWN_PERIOD="${COOLDOWN_PERIOD:-1800}"  # 30 minutes

# Ensure directories exist
mkdir -p "$LOG_DIR" "$STATE_DIR"

# Logging
log() {
    local level="${1:-INFO}"
    shift
    local msg="$*"
    local ts
    ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    echo "[$ts] [HEALER] [$level] $msg" | tee -a "$LOG_DIR/healer-trigger.log"
    echo "{\"ts\":\"$ts\",\"level\":\"$level\",\"message\":\"$msg\"}" >> "$LOG_DIR/healer-trigger.log.jsonl"
}

# ============================================================================
# COOLDOWN MANAGEMENT
# ============================================================================

cooldown_file() {
    local target="$1"
    echo "$STATE_DIR/healer-cooldown-${target}"
}

is_on_cooldown() {
    local target="$1"
    local file
    file=$(cooldown_file "$target")
    
    if [ -f "$file" ]; then
        local last_triggered
        last_triggered=$(cat "$file")
        local now
        now=$(date +%s)
        local elapsed=$((now - last_triggered))
        if [ "$elapsed" -lt "$COOLDOWN_PERIOD" ]; then
            echo "$((COOLDOWN_PERIOD - elapsed))"
            return 0
        fi
    fi
    return 1
}

set_cooldown() {
    local target="$1"
    local file
    file=$(cooldown_file "$target")
    date +%s > "$file"
}

clear_cooldown() {
    local target="$1"
    local file
    file=$(cooldown_file "$target")
    rm -f "$file"
}

# ============================================================================
# MARKER MANAGEMENT
# ============================================================================

create_marker() {
    local target="$1"
    local reason="$2"
    local marker_id="healer-$(date +%s)-$$"
    local marker_file="$STATE_DIR/healer-marker-${marker_id}.json"
    
    cat > "$marker_file" << EOF
{
  "marker_id": "$marker_id",
  "target": "$target",
  "reason": "$reason",
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "healer_agent": "$HEALER_AGENT",
  "status": "pending",
  "verifications": []
}
EOF
    
    echo "$marker_id"
}

update_marker() {
    local marker_id="$1"
    local status="$2"
    local message="${3:-}"
    
    local marker_file
    marker_file=$(ls "$STATE_DIR"/healer-marker-*"${marker_id}"*.json 2>/dev/null | head -1)
    
    if [ -f "$marker_file" ]; then
        local tmp_file="${marker_file}.tmp"
        python3 << EOF 2>/dev/null || true
import json
import sys

try:
    with open('$marker_file', 'r') as f:
        data = json.load(f)
    
    data['status'] = '$status'
    data['updated_at'] = '$(date -u +%Y-%m-%dT%H:%M:%SZ)'
    
    if '$message':
        data['verifications'].append({
            'timestamp': '$(date -u +%Y-%m-%dT%H:%M:%SZ)',
            'message': '$message'
        })
    
    with open('$tmp_file', 'w') as f:
        json.dump(data, f, indent=2)
    
    import os
    os.rename('$tmp_file', '$marker_file')
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)
EOF
    fi
}

# ============================================================================
# TARGETED HEALING ACTIONS
# ============================================================================

# Send nudge to wake up idle session
heal_with_nudge() {
    local target="$1"
    local reason="$2"
    local session_age="${3:-unknown}"
    
    log INFO "Healing $target with nudge (reason: $reason)"
    
    local nudge_msg
    nudge_msg="HEALER: Your session has been idle for ${session_age}s ($reason). Run gt prime && bd prime. Check gt hook. If stuck, run gt handoff."
    
    if command -v gt >/dev/null 2>&1; then
        if gt nudge "$target" "$nudge_msg" 2>/dev/null; then
            log INFO "Nudge sent to $target"
            return 0
        else
            log WARN "Failed to nudge $target"
            return 1
        fi
    else
        log ERROR "gt command not available"
        return 1
    fi
}

# Send mail with detailed instructions
heal_with_mail() {
    local target="$1"
    local reason="$2"
    local details="${3:-}"
    
    log INFO "Healing $target with mail (reason: $reason)"
    
    if ! command -v gt >/dev/null 2>&1; then
        log ERROR "gt command not available"
        return 1
    fi
    
    local subject="Healer: Idle Session Recovery"
    local body="Your session has been flagged as idle/stuck.

Reason: $reason
Details: $details

Recommended Actions:
1. Run: gt prime && bd prime
2. Check: gt hook
3. If work is stuck, consider: gt handoff
4. Resume productive work

If you need assistance, contact the overseer.

---
This is an automated message from the gastowndocs healer system."

    if gt mail send "$target" -s "$subject" -m "$body" 2>/dev/null; then
        log INFO "Mail sent to $target"
        return 0
    else
        log WARN "Failed to send mail to $target"
        return 1
    fi
}

# Force handoff for critical idle sessions (last resort)
heal_with_force_handoff() {
    local target="$1"
    local reason="$2"
    
    log WARN "CRITICAL: Forcing handoff for $target (reason: $reason)"
    
    # This would require more invasive action
    # For now, just escalate to overseer
    if command -v gt >/dev/null 2>&1; then
        gt mail send --human -s "CRITICAL: Force Handoff Needed for $target" -m "Session $target has exceeded critical idle threshold.

Reason: $reason
Action: Force handoff or manual intervention required.

Timestamp: $(date -u)" 2>/dev/null || true
    fi
}

# ============================================================================
# MAIN HEALING LOGIC
# ============================================================================

heal_session() {
    local target="$1"
    local reason="$2"
    local severity="${3:-normal}"  # normal, stale, critical
    local session_age="${4:-unknown}"
    
    log INFO "Starting healing for $target (severity: $severity, reason: $reason)"
    
    # Check cooldown
    local cooldown_remaining
    if cooldown_remaining=$(is_on_cooldown "$target"); then
        log WARN "Healer on cooldown for $target (${cooldown_remaining}s remaining)"
        return 1
    fi
    
    # Create marker
    local marker_id
    marker_id=$(create_marker "$target" "$reason")
    log INFO "Created marker: $marker_id"
    
    # Set cooldown immediately to prevent duplicate dispatches
    set_cooldown "$target"
    
    # Execute healing based on severity
    case "$severity" in
        normal)
            heal_with_nudge "$target" "$reason" "$session_age"
            update_marker "$marker_id" "completed" "Nudge sent"
            ;;
        stale)
            heal_with_nudge "$target" "$reason" "$session_age"
            heal_with_mail "$target" "$reason" "Session age: ${session_age}s"
            update_marker "$marker_id" "completed" "Nudge and mail sent"
            ;;
        critical)
            heal_with_nudge "$target" "$reason" "$session_age"
            heal_with_mail "$target" "$reason" "CRITICAL: Session age ${session_age}s exceeds threshold"
            heal_with_force_handoff "$target" "$reason"
            update_marker "$marker_id" "escalated" "Critical - escalated to overseer"
            ;;
        *)
            log ERROR "Unknown severity: $severity"
            update_marker "$marker_id" "failed" "Unknown severity"
            return 1
            ;;
    esac
    
    log INFO "Healing complete for $target"
    return 0
}

# ============================================================================
# CLI INTERFACE
# ============================================================================

usage() {
    cat << EOF
Usage: $0 <command> [options]

Commands:
  heal <target> <reason> [severity] [age]  - Heal specific session
  cooldown <target>                        - Check cooldown for target
  clear <target>                           - Clear cooldown for target
  status                                   - Show healer status
  verify <marker_id>                       - Verify marker status

Severity levels: normal, stale, critical

Examples:
  $0 heal gastowndocs/crew/nic idle_session stale 7200
  $0 cooldown gastowndocs/crew/nic
  $0 status
EOF
}

case "${1:-}" in
    heal)
        if [ $# -lt 3 ]; then
            usage
            exit 1
        fi
        heal_session "$2" "$3" "${4:-normal}" "${5:-unknown}"
        ;;
    cooldown)
        if [ $# -lt 2 ]; then
            usage
            exit 1
        fi
        if is_on_cooldown "$2" >/dev/null 2>&1; then
            echo "On cooldown ($(is_on_cooldown "$2")s remaining)"
        else
            echo "Not on cooldown"
        fi
        ;;
    clear)
        if [ $# -lt 2 ]; then
            usage
            exit 1
        fi
        clear_cooldown "$2"
        echo "Cooldown cleared for $2"
        ;;
    status)
        echo "=== Healer Status ==="
        echo "Agent: $HEALER_AGENT"
        echo "Cooldown period: ${COOLDOWN_PERIOD}s"
        echo ""
        echo "Active markers:"
        ls -la "$STATE_DIR"/healer-marker-*.json 2>/dev/null || echo "  (none)"
        echo ""
        echo "Active cooldowns:"
        for f in "$STATE_DIR"/healer-cooldown-* 2>/dev/null; do
            if [ -f "$f" ]; then
                local target
                target=$(basename "$f" | sed 's/healer-cooldown-//')
                local remaining
                remaining=$(is_on_cooldown "$target" 2>/dev/null) || remaining="0"
                if [ "$remaining" != "0" ]; then
                    echo "  $target: ${remaining}s remaining"
                fi
            fi
        done
        ;;
    verify)
        if [ $# -lt 2 ]; then
            usage
            exit 1
        fi
        marker_file=$(ls "$STATE_DIR"/healer-marker-*"$2"*.json 2>/dev/null | head -1)
        if [ -f "$marker_file" ]; then
            cat "$marker_file"
        else
            echo "Marker not found: $2"
            exit 1
        fi
        ;;
    *)
        usage
        exit 1
        ;;
esac
