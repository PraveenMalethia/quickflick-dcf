#!/bin/bash
set -e

KEYFILE="/data/db/mongo-keyfile"

# ── Generate keyfile if missing (needed before mongod starts with --keyFile) ──
if [ ! -f "$KEYFILE" ]; then
  echo "[entrypoint] Generating replica set keyfile..."
  openssl rand -base64 756 > "$KEYFILE"
  chmod 400 "$KEYFILE"
  # mongod runs as UID 999 inside the container
  chown 999:999 "$KEYFILE" 2>/dev/null || true
  echo "[entrypoint] Keyfile created."
else
  echo "[entrypoint] Keyfile already exists."
fi

# ── Delegate to official mongo entrypoint (handles MONGO_INITDB_ROOT_*, then exec mongod) ──
exec /usr/local/bin/docker-entrypoint.sh "$@"