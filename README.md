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

The `mongodb` service starts with:
```
command: ["--replSet", "rs0", "--bind_ip_all", "--keyFile", "/data/db/mongo-keyfile"]
```

### ⚠️ Important: MONGO_URI must include `replicaSet=rs0`

```
MONGO_URI=mongodb://admin:password@mongodb:27017/quickflick?authSource=admin&replicaSet=rs0
```

Without `&replicaSet=rs0`, Mongoose will not use transactions and you'll get the error:
`Transaction numbers are only allowed on a replica set member or mongos`

## Manual Replica Set Setup (one-time)

The replica set must be **initiated once** after the stack first starts. This is a manual step — there is no auto-init container.

### Step 1: Deploy the stack

In Portainer → Stacks → quickflick → Editor, update the compose content, then click "Update the stack".

### Step 2: Generate the keyfile (first time only)

The `--keyFile` flag requires a keyfile to exist. On first deploy, create it inside the container:

```bash
docker exec -it quickflick-mongodb-1 bash -c "openssl rand -base64 756 > /data/db/mongo-keyfile && chmod 400 /data/db/mongo-keyfile && chown 999:999 /data/db/mongo-keyfile"
```

> **Note:** If the container fails to start with `security.keyFile is required when authorization is enabled with replica sets`, the keyfile is missing. Create it, then restart the container.

### Step 3: Initiate the replica set

```bash
docker exec -it quickflick-mongodb-1 mongosh -u admin -p YOUR_PASSWORD --authenticationDatabase admin --eval "rs.initiate({_id: 'rs0', members: [{_id: 0, host: 'localhost:27017'}]})"
```

### Step 4: Verify

```bash
docker exec -it quickflick-mongodb-1 mongosh -u admin -p YOUR_PASSWORD --authenticationDatabase admin --eval "rs.status().members[0].stateStr"
```

Should return `PRIMARY`.

### Step 5: Restart the backend

After the replica set is PRIMARY, restart the backend container so it reconnects with the replica set connection string.

## Notes

- All env vars come from `stack.env` / Portainer env vars — no `environment:` blocks in compose
- Backend listens on port 3000 (set via `PORT` env var)
- Mongo Express available on port 8081 via NPM
- The replica set initiation is **manual** — run it once after first deploy