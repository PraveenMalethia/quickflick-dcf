#!/bin/bash
set -e

# ── Generate keyfile if missing ────────────────────────────
KEYFILE="/data/db/mongo-keyfile"
if [ ! -f "$KEYFILE" ]; then
  echo "[rs-init] Generating replica set keyfile..."
  openssl rand -base64 756 > "$KEYFILE"
  chmod 400 "$KEYFILE"
  chown 999:999 "$KEYFILE"
  echo "[rs-init] Keyfile created."
else
  echo "[rs-init] Keyfile already exists, skipping generation."
fi

# ── Start mongod in the background with replica set flag ────
echo "[rs-init] Starting mongod with --replSet rs0..."
mongod --replSet rs0 --bind_ip_all --keyFile "$KEYFILE" &
MONGOD_PID=$!

# ── Wait for mongod to be ready ────────────────────────────
echo "[rs-init] Waiting for mongod to accept connections..."
until mongosh --eval "db.runCommand('ping').ok" --quiet > /dev/null 2>&1; do
  sleep 1
done
echo "[rs-init] mongod is ready."

# ── Initiate replica set if not yet initiated ──────────────
IS_INITIATED=$(mongosh --quiet --eval "rs.status().ok" 2>/dev/null || echo "0")
if [ "$IS_INITIATED" != "1" ]; then
  echo "[rs-init] Initiating replica set rs0..."
  mongosh --eval "
    rs.initiate({
      _id: 'rs0',
      members: [{ _id: 0, host: 'mongodb:27017' }]
    })
  " --quiet
  echo "[rs-init] Replica set initiation command sent."

  # Wait for PRIMARY
  echo "[rs-init] Waiting for node to become PRIMARY..."
  until mongosh --quiet --eval "rs.status().members[0].stateStr" 2>/dev/null | grep -q PRIMARY; do
    sleep 2
  done
  echo "[rs-init] Replica set is PRIMARY. Ready."
else
  echo "[rs-init] Replica set already initiated, skipping."
fi

# ── Bring mongod to foreground (keep container alive) ──────
echo "[rs-init] Handing off to mongod (PID $MONGOD_PID)..."
wait $MONGOD_PID