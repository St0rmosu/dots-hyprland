#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_PYTHON="$DIR/venv/bin/python"
SYNC_PY="$DIR/sync.py"
TOKEN_FILE="$DIR/token.json"
CREDS_FILE="$DIR/credentials.json"

ensure_venv() {
    if [ ! -f "$VENV_PYTHON" ]; then
        echo "[Google Tasks Sync] Initializing Python virtual environment..."
        python3 -m venv "$DIR/venv"
        "$DIR/venv/bin/pip" install --no-cache-dir google-api-python-client google-auth-oauthlib
    fi
}

if [ "$1" = "--auth" ]; then
    ensure_venv
    "$VENV_PYTHON" "$SYNC_PY" --auth
    exit $?
fi

# In background / automated runs, do nothing if credentials or token don't exist yet
if [ ! -f "$CREDS_FILE" ] || [ ! -f "$TOKEN_FILE" ]; then
    exit 0
fi

ensure_venv

# Run sync with lock to prevent overlapping runs
LOCK_FILE="/tmp/google-tasks-sync.lock"
exec 200>"$LOCK_FILE"
flock -n 200 || exit 0

"$VENV_PYTHON" "$SYNC_PY" "$@"
