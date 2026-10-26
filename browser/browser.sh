#!/usr/bin/env bash
#
# browser.sh - BrowserPilot debug browser manager
#
# Start, stop, monitor and reset a dedicated Chromium-based browser profile
# with the Chrome DevTools Protocol (CDP) enabled. Intended for local
# development and browser automation (e.g. attaching Playwright or Puppeteer).
#
# Supported browsers: any Chromium-based browser that supports CDP
# (Brave, Google Chrome, Microsoft Edge, Chromium).
#
# Usage:   browser.sh [options] <command>
# Help:    browser.sh --help
#
# Security: the CDP endpoint is bound to 127.0.0.1 only. CDP grants full
# control of the browser, including authenticated sessions. Never expose it.
#
# Compatible with the Bash 3.2 shipped with macOS.

set -euo pipefail

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
readonly VERSION="2.0.0"
readonly SCRIPT_NAME="${0##*/}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Exit codes
readonly EX_OK=0
readonly EX_ERROR=1       # Generic failure
readonly EX_USAGE=2       # Invalid command line or configuration
readonly EX_STOPPED=3     # status: instance is not running
readonly EX_NOT_FOUND=4   # Browser executable missing or not executable
readonly EX_PORT_BUSY=5   # CDP port already in use
readonly EX_TIMEOUT=6     # CDP did not become ready in time

readonly CDP_HOST="127.0.0.1"

# ------------------------------------------------------------------------------
# Configuration (environment variables; command-line options take precedence)
# ------------------------------------------------------------------------------
BROWSER_NAME="${BROWSER_NAME:-brave}"
BROWSER_PATH="${BROWSER_PATH:-${BRAVE_PATH:-}}"   # BRAVE_PATH: legacy alias
PROFILE_NAME="${PROFILE_NAME:-ar}"
PORT="${PORT:-9222}"
START_TIMEOUT="${START_TIMEOUT:-15}"              # seconds
STOP_TIMEOUT="${STOP_TIMEOUT:-10}"                # seconds
MAX_LOG_BYTES="${MAX_LOG_BYTES:-5242880}"         # 5 MiB
HEADLESS="${HEADLESS:-0}"                         # 1 = run headless
BROWSER_EXTRA_ARGS="${BROWSER_EXTRA_ARGS:-}"      # extra flags, space-separated
BROWSER_ROOT="${BROWSER_ROOT:-$SCRIPT_DIR/testing-browser}"

# Parsed command line
COMMAND=""
COMMAND_ARG=""
SHOW_HELP=0
SHOW_VERSION=0
ASSUME_YES=0

# Derived paths (set by derive_paths)
PROFILE_DIR=""
RUNTIME_DIR=""
PID_FILE=""
LOG_FILE=""
CDP_URL=""

# ------------------------------------------------------------------------------
# Logging
# ------------------------------------------------------------------------------
if [[ -t 2 && -z "${NO_COLOR:-}" ]]; then
    C_RED=$'\033[31m'; C_YELLOW=$'\033[33m'; C_RESET=$'\033[0m'
else
    C_RED=""; C_YELLOW=""; C_RESET=""
fi

log_info()  { printf '%s\n' "$*"; }
log_warn()  { printf '%sWARNING:%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
log_error() { printf '%sERROR:%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; }

# die <exit-code> <message...>
die() {
    local code="$1"
    shift
    log_error "$*"
    exit "$code"
}

usage_error() {
    log_error "$*"
    printf "Try '%s --help' for more information.\n" "$SCRIPT_NAME" >&2
    exit "$EX_USAGE"
}

usage() {
    cat <<EOF
BrowserPilot debug browser manager $VERSION

Usage: $SCRIPT_NAME [options] <command>

Commands:
  start         Start the dedicated debug browser
  stop          Stop the instance started by this script
  restart       Stop, then start
  status        Show state, PID and CDP endpoint (exit 3 if not running)
  url           Print the CDP endpoint URL
  logs [N]      Show the last N log lines (default: 100)
  log-tail      Follow the log (Ctrl+C stops following, not the browser)
  reset         Delete the dedicated profile (asks for confirmation)

Options:
  -b, --browser NAME      Browser label: brave, chrome, edge, chromium
                          or a custom label (default: $BROWSER_NAME)
      --browser-path PATH Absolute path to the browser executable
  -p, --profile NAME      Profile name (default: $PROFILE_NAME)
  -P, --port PORT         Local CDP port (default: $PORT)
      --headless          Run without a visible window
  -y, --yes               Skip the confirmation prompt (reset)
  -h, --help              Show this help
  -V, --version           Show the version

Environment variables:
  BROWSER_NAME, BROWSER_PATH, PROFILE_NAME, PORT, START_TIMEOUT,
  STOP_TIMEOUT, MAX_LOG_BYTES, HEADLESS, BROWSER_EXTRA_ARGS, BROWSER_ROOT,
  NO_COLOR. (BRAVE_PATH is accepted as a legacy alias of BROWSER_PATH.)

Exit codes:
  0 success   1 error   2 usage   3 not running
  4 browser not found   5 port in use   6 CDP start timeout

Examples:
  $SCRIPT_NAME start
  $SCRIPT_NAME --browser chrome --profile qa --port 9333 start
  PORT=9333 PROFILE_NAME=dev $SCRIPT_NAME status
  $SCRIPT_NAME --yes reset
EOF
}

# ------------------------------------------------------------------------------
# Argument parsing and validation
# ------------------------------------------------------------------------------
need_value() {
    # need_value <option> <remaining-args-count-incl-option>
    [[ "$2" -ge 2 ]] || usage_error "Option $1 requires a value"
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)      SHOW_HELP=1 ;;
            -V|--version)   SHOW_VERSION=1 ;;
            -y|--yes)       ASSUME_YES=1 ;;
            --headless)     HEADLESS=1 ;;
            -b|--browser)   need_value "$1" "$#"; BROWSER_NAME="$2"; shift ;;
            --browser-path) need_value "$1" "$#"; BROWSER_PATH="$2"; shift ;;
            -p|--profile)   need_value "$1" "$#"; PROFILE_NAME="$2"; shift ;;
            -P|--port)      need_value "$1" "$#"; PORT="$2"; shift ;;
            -*)             usage_error "Unknown option: $1" ;;
            *)
                if [[ -z "$COMMAND" ]]; then
                    COMMAND="$1"
                elif [[ -z "$COMMAND_ARG" ]]; then
                    COMMAND_ARG="$1"
                else
                    usage_error "Unexpected argument: $1"
                fi
                ;;
        esac
        shift
    done
}

is_uint() { [[ "$1" =~ ^[0-9]+$ ]]; }

validate_name() {
    # validate_name <label> <value>
    [[ "$2" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] ||
        usage_error "$1 must start with a letter or digit and contain only letters, digits, '.', '_' or '-': '$2'"
}

validate_config() {
    validate_name "Browser name" "$BROWSER_NAME"
    validate_name "Profile name" "$PROFILE_NAME"

    is_uint "$PORT" && [[ "$((10#$PORT))" -ge 1 && "$((10#$PORT))" -le 65535 ]] ||
        usage_error "Port must be an integer between 1 and 65535: '$PORT'"
    PORT="$((10#$PORT))"

    local v
    for v in START_TIMEOUT STOP_TIMEOUT MAX_LOG_BYTES; do
        is_uint "${!v}" || usage_error "$v must be a non-negative integer: '${!v}'"
    done

    [[ "$HEADLESS" == "0" || "$HEADLESS" == "1" ]] ||
        usage_error "HEADLESS must be 0 or 1: '$HEADLESS'"

    case "$BROWSER_EXTRA_ARGS" in
        *--remote-debugging-port*|*--remote-debugging-address*|*--user-data-dir*)
            usage_error "BROWSER_EXTRA_ARGS must not set CDP port, address or profile; use the dedicated options"
            ;;
    esac
}

derive_paths() {
    PROFILE_DIR="$BROWSER_ROOT/browser-data/$BROWSER_NAME-$PROFILE_NAME"
    RUNTIME_DIR="$BROWSER_ROOT/runtime"
    PID_FILE="$RUNTIME_DIR/$BROWSER_NAME-$PROFILE_NAME.pid"
    LOG_FILE="$RUNTIME_DIR/$BROWSER_NAME-$PROFILE_NAME.log"
    CDP_URL="http://$CDP_HOST:$PORT"
}

default_browser_path() {
    case "$1" in
        brave)    printf '%s' "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser" ;;
        chrome)   printf '%s' "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ;;
        edge)     printf '%s' "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge" ;;
        chromium) printf '%s' "/Applications/Chromium.app/Contents/MacOS/Chromium" ;;
        *)        return 1 ;;
    esac
}

resolve_browser_path() {
    if [[ -z "$BROWSER_PATH" ]]; then
        BROWSER_PATH="$(default_browser_path "$BROWSER_NAME")" ||
            die "$EX_USAGE" "No default path for browser '$BROWSER_NAME'. Set --browser-path or BROWSER_PATH."
    fi
    [[ -x "$BROWSER_PATH" ]] ||
        die "$EX_NOT_FOUND" "Browser executable not found or not executable: $BROWSER_PATH"
}

require_commands() {
    local cmd
    for cmd in "$@"; do
        command -v "$cmd" >/dev/null 2>&1 || die "$EX_ERROR" "Required command not found: $cmd"
    done
}

# ------------------------------------------------------------------------------
# Process and endpoint helpers
# ------------------------------------------------------------------------------
read_pid() {
    [[ -f "$PID_FILE" ]] || return 0
    tr -d '[:space:]' <"$PID_FILE"
}

# True only if the saved PID is alive AND its command line references this
# dedicated profile. Guards against signalling a reused PID.
is_running() {
    local pid cmd
    pid="$(read_pid)"

    [[ -n "$pid" ]] || return 1
    is_uint "$pid" || return 1
    kill -0 "$pid" 2>/dev/null || return 1

    cmd="$(ps -p "$pid" -o command= 2>/dev/null || true)"
    [[ "$cmd" == *"--user-data-dir=$PROFILE_DIR"* ]]
}

cdp_ready() {
    curl -fsS --max-time 1 "$CDP_URL/json/version" >/dev/null 2>&1
}

port_in_use() {
    if command -v lsof >/dev/null 2>&1; then
        lsof -nP -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1
    else
        (exec 3<>"/dev/tcp/$CDP_HOST/$PORT") 2>/dev/null
    fi
}

rotate_log() {
    [[ -f "$LOG_FILE" ]] || return 0

    local size
    size="$(wc -c <"$LOG_FILE" | tr -d '[:space:]')"
    if [[ "$size" -gt "$MAX_LOG_BYTES" ]]; then
        mv -f "$LOG_FILE" "$LOG_FILE.1"
    fi
}

# Terminate a browser we launched that failed to become ready.
abort_start() {
    local pid="$1"
    kill -TERM "$pid" 2>/dev/null || true
    rm -f "$PID_FILE"
}

# ------------------------------------------------------------------------------
# Commands
# ------------------------------------------------------------------------------
cmd_start() {
    require_commands curl ps kill nohup
    resolve_browser_path

    if is_running; then
        log_info "$BROWSER_NAME already running (PID $(read_pid))"
        log_info "CDP: $CDP_URL"
        return "$EX_OK"
    fi

    rm -f "$PID_FILE"

    if port_in_use; then
        die "$EX_PORT_BUSY" "Port $PORT is already in use. Choose another --port or stop its owner."
    fi

    mkdir -p "$RUNTIME_DIR" "$PROFILE_DIR"

    # Safe: no verified process owns this profile, so any locks are stale.
    rm -f "$PROFILE_DIR"/Singleton{Lock,Cookie,Socket}

    rotate_log

    local args=(
        "--remote-debugging-port=$PORT"
        "--remote-debugging-address=$CDP_HOST"
        "--user-data-dir=$PROFILE_DIR"
        --no-first-run
        --no-default-browser-check
    )
    [[ "$HEADLESS" == "1" ]] && args+=("--headless=new")
    if [[ -n "$BROWSER_EXTRA_ARGS" ]]; then
        local extra
        read -r -a extra <<<"$BROWSER_EXTRA_ARGS"
        args+=("${extra[@]}")
    fi

    log_info "Starting $BROWSER_NAME (profile '$PROFILE_NAME', port $PORT)..."

    printf '\n--- %s starting: %s ---\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')" "$BROWSER_NAME" >>"$LOG_FILE"

    # Launch the executable directly so $! is the browser's own PID.
    nohup "$BROWSER_PATH" "${args[@]}" >>"$LOG_FILE" 2>&1 </dev/null &
    local pid=$!
    disown "$pid" 2>/dev/null || true
    printf '%s\n' "$pid" >"$PID_FILE"

    local i max=$((START_TIMEOUT * 4))
    for ((i = 0; i < max; i++)); do
        if ! kill -0 "$pid" 2>/dev/null; then
            log_error "$BROWSER_NAME exited during startup. Last log lines:"
            tail -n 30 "$LOG_FILE" >&2 || true
            rm -f "$PID_FILE"
            return "$EX_ERROR"
        fi

        if cdp_ready; then
            log_info "$BROWSER_NAME debug instance ready."
            log_info "  PID:     $pid"
            log_info "  CDP:     $CDP_URL"
            log_info "  Profile: $PROFILE_DIR"
            log_info "  Log:     $LOG_FILE"
            return "$EX_OK"
        fi
        sleep 0.25
    done

    abort_start "$pid"
    log_error "CDP not ready after ${START_TIMEOUT}s; the browser was terminated."
    log_error "Inspect the log: $SCRIPT_NAME logs"
    return "$EX_TIMEOUT"
}

cmd_stop() {
    require_commands ps kill

    if ! is_running; then
        rm -f "$PID_FILE"
        log_info "$BROWSER_NAME is not running (profile '$PROFILE_NAME')."
        if cdp_ready; then
            log_warn "CDP still responds on $CDP_URL but is not owned by this instance."
            log_warn "Identify the owner with: lsof -nP -iTCP:$PORT -sTCP:LISTEN"
        fi
        return "$EX_OK"
    fi

    local pid i max=$((STOP_TIMEOUT * 2))
    pid="$(read_pid)"

    log_info "Stopping $BROWSER_NAME (PID $pid)..."
    kill -TERM "$pid" 2>/dev/null || true

    for ((i = 0; i < max; i++)); do
        if ! is_running; then
            rm -f "$PID_FILE"
            log_info "Stopped."
            return "$EX_OK"
        fi
        sleep 0.5
    done

    # Re-verify identity immediately before force-killing (PID reuse guard).
    if is_running; then
        log_warn "Graceful shutdown timed out after ${STOP_TIMEOUT}s; sending SIGKILL."
        kill -KILL "$pid" 2>/dev/null || true
        sleep 0.5
    fi

    rm -f "$PID_FILE"
    log_info "Stopped."
}

cmd_restart() {
    cmd_stop
    cmd_start
}

cmd_status() {
    require_commands curl ps kill

    if is_running; then
        local health="not-responding"
        cdp_ready && health="responding"
        log_info "Status:  RUNNING"
        log_info "Browser: $BROWSER_NAME"
        log_info "PID:     $(read_pid)"
        log_info "CDP:     $CDP_URL ($health)"
        log_info "Profile: $PROFILE_DIR"
        log_info "Log:     $LOG_FILE"
        return "$EX_OK"
    fi

    log_info "Status:  STOPPED (no verified process for profile '$PROFILE_NAME')"
    if cdp_ready; then
        log_warn "CDP responds on $CDP_URL, but the saved PID does not match."
    fi
    return "$EX_STOPPED"
}

cmd_url() {
    printf '%s\n' "$CDP_URL"
}

cmd_logs() {
    local lines="${COMMAND_ARG:-100}"
    is_uint "$lines" || usage_error "logs: N must be a non-negative integer: '$lines'"
    [[ -f "$LOG_FILE" ]] || die "$EX_ERROR" "No log file yet: $LOG_FILE"
    tail -n "$lines" "$LOG_FILE"
}

cmd_log_tail() {
    [[ -f "$LOG_FILE" ]] || die "$EX_ERROR" "No log file yet: $LOG_FILE"
    exec tail -f "$LOG_FILE"
}

cmd_reset() {
    require_commands curl ps kill

    # Defence in depth: only ever delete inside the managed browser-data tree.
    [[ "$PROFILE_DIR" == "$BROWSER_ROOT/browser-data/"?* ]] ||
        die "$EX_ERROR" "Refusing to delete a path outside the managed profile directory: $PROFILE_DIR"

    if is_running; then
        die "$EX_ERROR" "$BROWSER_NAME is running. Run '$SCRIPT_NAME stop' first."
    fi
    if cdp_ready; then
        die "$EX_ERROR" "CDP port $PORT is responding. Stop its owner before resetting."
    fi
    if [[ ! -d "$PROFILE_DIR" ]]; then
        log_info "Nothing to reset: $PROFILE_DIR does not exist."
        return "$EX_OK"
    fi

    log_info "This will permanently delete the profile (cookies, sessions, settings):"
    log_info "  $PROFILE_DIR"

    if [[ "$ASSUME_YES" -ne 1 ]]; then
        [[ -t 0 ]] || die "$EX_ERROR" "Not an interactive terminal. Re-run with --yes to confirm."
        local answer
        read -r -p "Continue? [y/N] " answer
        case "$answer" in
            [yY]|[yY][eE][sS]) ;;
            *) log_info "Cancelled."; return "$EX_OK" ;;
        esac
    fi

    rm -rf "${PROFILE_DIR:?}"
    rm -f "$PID_FILE"
    log_info "Profile reset. It will be recreated on the next start."
}

# ------------------------------------------------------------------------------
# Entry point
# ------------------------------------------------------------------------------
main() {
    parse_args "$@"

    if [[ "$SHOW_VERSION" -eq 1 ]]; then
        printf '%s %s\n' "$SCRIPT_NAME" "$VERSION"
        return "$EX_OK"
    fi

    if [[ "$SHOW_HELP" -eq 1 || "$COMMAND" == "help" ]]; then
        usage
        return "$EX_OK"
    fi

    if [[ -z "$COMMAND" ]]; then
        usage >&2
        return "$EX_USAGE"
    fi

    if [[ -n "$COMMAND_ARG" && "$COMMAND" != "logs" ]]; then
        usage_error "Unexpected argument for '$COMMAND': $COMMAND_ARG"
    fi

    validate_config
    derive_paths

    case "$COMMAND" in
        start)    cmd_start ;;
        stop)     cmd_stop ;;
        restart)  cmd_restart ;;
        status)   cmd_status ;;
        url)      cmd_url ;;
        logs)     cmd_logs ;;
        log-tail) cmd_log_tail ;;
        reset)    cmd_reset ;;
        *)        usage_error "Unknown command: $COMMAND" ;;
    esac
}

main "$@"
