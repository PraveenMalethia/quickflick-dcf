# QuickFlick DCF

Docker Compose Fleet configuration for QuickFlick deployment.

## Services

| Service | Description |
|---------|-------------|
| mongodb | MongoDB 7.0 single-node replica set (supports transactions) |
| rs-init | One-shot init container: generates keyfile + initiates replica set |
| backend | QuickFlick Backend API |
| admin | QuickFlick Admin Panel |
| frontend | QuickFlick Customer PWA |
| mongo-express | MongoDB admin UI |
| redis | Cache/session store (staging only) |

## Branches

- `main` → production compose (`docker-compose.main.yml`)
- `staging` → staging compose (`docker-compose.staging.yml`)

## MongoDB Replica Set

MongoDB runs as a **single-node replica set** (`rs0`) to support multi-document transactions.

### Architecture

1. **`mongodb` service** — Custom image (`mongo/Dockerfile`) that:
   - Generates `/data/db/mongo-keyfile` on first boot (required for auth + replSet)
   - Delegates to the official `docker-entrypoint.sh` (which creates the root user from `MONGO_INITDB_*` env vars)
   - Starts with `--replSet rs0 --bind_ip_all --keyFile /data/db/mongo-keyfile`

2. **`rs-init` service** — One-shot init container that:
   - Waits for mongodb to be healthy
   - Runs `rs.initiate()` if the replica set isn't initiated yet (idempotent)
   - Exits 0 on success; backend starts after this completes

### ⚠️ Important: MONGO_URI must include `replicaSet=rs0`

```
MONGO_URI=mongodb://admin:password@mongodb:27017/quickflick?authSource=admin&replicaSet=rs0
```

Without `&replicaSet=rs0`, Mongoose will not use transactions and you'll get the error:
`Transaction numbers are only allowed on a replica set member or mongos`

## Portainer Deployment

1. Push changes to this repo
2. In Portainer → Stacks → quickflick → Editor, update the compose content
3. In Portainer env vars, **make sure `MONGO_URI` includes `&replicaSet=rs0`**
4. Click "Update the stack" — Portainer will:
   - Build the custom `mongodb` image (keyfile generation entrypoint)
   - Start mongodb → wait for healthcheck → run rs-init → start backend

### First-time deployment (fresh volume)

Everything is automatic — keyfile generation, root user creation, and rs.initiate all happen automatically.

### Upgrading from standalone (existing data volume)

The rs-init container detects an existing replica set and skips initiation. Existing data is preserved. The keyfile is generated on the shared volume and persists across restarts.

## Notes

- All env vars come from `stack.env` / Portainer env vars — no `environment:` blocks in compose
- Backend listens on port 3000 (set via `PORT` env var)
- Mongo Express available on port 8081 via NPM
- `mongodb` has a healthcheck; backend waits for `rs-init` to complete before starting