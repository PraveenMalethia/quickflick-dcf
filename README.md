# QuickFlick DCF

Docker Compose Fleet configuration for QuickFlick deployment.

## Services

| Service | Description |
|---------|-------------|
| mongodb | MongoDB 6.0 database |
| backend | QuickFlick Backend API |
| mongo-express | MongoDB admin UI |

## Branches

- `main` → production compose (`docker-compose.main.yml`)
- `staging` → staging compose (`docker-compose.staging.yml`)

## Portainer

Stack source: this repo. Environment variables set via Portainer UI → Environment variables.

## Notes

- All env vars come from `stack.env` — no `environment:` blocks in compose
- Backend listens on port 3000 (set via `PORT` env var)
- Mongo Express available on port 8081 via NPM