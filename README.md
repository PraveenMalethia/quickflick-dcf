# QuickFlick DCF

Docker Compose Fleet configuration for QuickFlick deployment.

## Services

| Service | Description |
|---------|-------------|
| mongodb | MongoDB 7.0 single-node replica set (supports transactions) |
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

The custom `mongo/Dockerfile` + `mongo/rs-init.sh` entrypoint:
1. Generates a keyfile for internal replica set auth (idempotent — skips if exists)
2. Starts `mongod --replSet rs0 --keyFile ...`
3. Auto-initiates the replica set on first boot (idempotent — skips if already initiated)
4. Waits for PRIMARY status before handing off

**No manual `rs.initiate()` step is needed.** The container handles it automatically.

## Portainer Deployment

1. Push changes to this repo
2. In Portainer → Stacks → quickflick → Editor, update the compose content from this repo
3. Update the `stack.env` environment variables in Portainer UI — **make sure `MONGO_URI` includes `&replicaSet=rs0`**
4. Click "Update the stack"
5. MongoDB will auto-initiate the replica set on startup

### ⚠️ First-time deployment

If deploying to a **fresh volume** (no existing data):
- The init script auto-creates the keyfile and initiates the replica set
- No manual steps required

If deploying to an **existing volume** (upgrading from standalone):
- Stop the stack first
- The init script detects existing data and initiates the replica set
- All existing data is preserved

## Notes

- All env vars come from `stack.env` — no `environment:` blocks in compose
- Backend listens on port 3000 (set via `PORT` env var)
- Mongo Express available on port 8081 via NPM
- `mongodb` service has a healthcheck (`rs.status().ok`) — backend waits for it via `depends_on: condition: service_healthy`