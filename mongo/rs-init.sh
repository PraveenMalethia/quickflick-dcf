#!/bin/bash
# One-shot: initiate replica set after mongodb is healthy.
# Runs as an init container, exits 0 on success.
set -e

# ── Wait for mongodb to accept auth connections ────────────────
echo "[rs-init] Waiting for mongodb..."
until mongosh --host mongodb \
  -u "$MONGO_INITDB_ROOT_USERNAME" \
  -p "$MONGO_INITDB_ROOT_PASSWORD" \
  --authenticationDatabase admin \
  --quiet \
  --eval "db.runCommand('ping').ok" > /dev/null 2>&1; do
  sleep 2
done
echo "[rs-init] mongodb is ready."

# ── Initiate replica set if not yet initiated ──────────────────
IS_INITIATED=$(mongosh --host mongodb \
  -u "$MONGO_INITDB_ROOT_USERNAME" \
  -p "$MONGO_INITDB_ROOT_PASSWORD" \
  --authenticationDatabase admin \
  --quiet \
  --eval "try { rs.status().ok } catch(e) { 0 }" 2>/dev/null || echo "0")

if [ "$IS_INITIATED" != "1" ]; then
  echo "[rs-init] Initiating replica set rs0..."
  mongosh --host mongodb \
    -u "$MONGO_INITDB_ROOT_USERNAME" \
    -p "$MONGO_INITDB_ROOT_PASSWORD" \
    --authenticationDatabase admin \
    --eval "
      rs.initiate({
        _id: 'rs0',
        members: [{ _id: 0, host: 'localhost:27017' }]
      })
    "

  echo "[rs-init] Waiting for PRIMARY..."
  until mongosh --host mongodb \
    -u "$MONGO_INITDB_ROOT_USERNAME" \
    -p "$MONGO_INITDB_ROOT_PASSWORD" \
    --authenticationDatabase admin \
    --quiet \
    --eval "rs.status().members[0].stateStr" 2>/dev/null | grep -q PRIMARY; do
    sleep 2
  done
  echo "[rs-init] Replica set is PRIMARY. Done."
else
  echo "[rs-init] Replica set already initiated."
fi