---
name: docker-compose-ops
description: >
  Use this skill for ANY task involving Docker containers, docker compose, or local infrastructure
  services (mongo, redis, grafana, prometheus). Covers: starting/stopping dev, test, e2e, or prod
  environments; checking container status, health, or resource usage (memory, CPU); viewing or filtering
  container logs; diagnosing why a service crashes, restarts, or won't start (port conflicts, OOM,
  missing deps); managing volumes and networks; running e2e or integration tests that live in
  docker-compose files. Trigger even when Docker isn't explicitly mentioned — if the user wants to
  "поднять дев", check what's running, debug a restarting redis/mongo, see container memory usage,
  or run e2e tests from compose, this is the right skill.
---

# Docker Compose Operations — My Zodiac AI

You are an operations assistant for the My Zodiac AI monorepo's Docker infrastructure. Your job is to
execute docker compose commands directly and present results clearly — both as terminal output and,
when appropriate, as a structured markdown report.

## Project Layout

The monorepo has **5 compose files** across **4 environments**:

| File | Location | Environment | Default services |
|------|----------|-------------|-----------------|
| `docker-compose.yml` | root | **dev** | mongo, redis, prometheus, alertmanager, grafana |
| `docker-compose.prod.yml` | root | **prod** | backend, prometheus, alertmanager, grafana |
| `docker-compose.test.yml` | root | **test** | mongo-test, redis-test, backend-test + profiles: load, chaos, validation, memory, features, frontend, frontend-e2e, lighthouse, report |
| `front/docker-compose.e2e.yml` | front/ | **e2e** | mongodb-test, redis-test, backend-test, frontend-test, playwright |
| `front/docker-compose.test.yml` | front/ | **front-test** | test-runner, chrome, firefox, edge, mock-server + visual-regression, lighthouse, axe |

The project root is the directory containing `docker-compose.yml` (the monorepo root).

## Environment Aliases

Users will refer to environments casually. Map their intent:

- **dev** / **разработка** / **поднять дев** / default → `docker-compose.yml`
- **prod** / **продакшн** / **production** → `docker-compose.prod.yml`
- **test** / **тесты** / **backend tests** → `docker-compose.test.yml`
- **e2e** / **playwright** / **end-to-end** → `front/docker-compose.e2e.yml`
- **front-test** / **frontend tests** / **browser tests** → `front/docker-compose.test.yml`

When the user doesn't specify an environment, default to **dev**.

## Core Operations

### 1. Start / Stop / Restart

Always show the command being run before executing it — this helps the user understand what's happening
and builds trust.

```bash
# Pattern for starting
cd <project-root> && docker compose -f <file> up -d [service...]

# Pattern for stopping
cd <project-root> && docker compose -f <file> down [--volumes] [--remove-orphans]

# Pattern for restarting a single service
cd <project-root> && docker compose -f <file> restart <service>
```

For `docker-compose.test.yml`, many services use **profiles**. If the user asks to run load tests,
chaos tests, frontend tests, etc., include `--profile <name>`:

| Profile | Services |
|---------|----------|
| `load` | load-test |
| `chaos` | chaos-test |
| `validation` | release-validation |
| `memory` | memory-test |
| `features` | feature-flag-test |
| `frontend` | frontend-test |
| `frontend-e2e` | backend-api, frontend-e2e, frontend-e2e-runner |
| `lighthouse` | lighthouse |
| `report` | report-aggregator |

### 2. Health Check

This is one of the most common operations. Run a comprehensive check and present results as a table.

**Steps:**
1. Run `docker compose -f <file> ps --format json` to get container states
2. For each running container, check its health status via `docker inspect --format='{{json .State.Health}}' <container>`
3. Check port bindings with `docker compose -f <file> port <service> <port>` or from `ps` output
4. Present a summary table:

```
Service        Status    Health     Ports              Uptime
─────────────────────────────────────────────────────────────
mongo          running   healthy    0.0.0.0:27017→27017  2h 15m
redis          running   healthy    0.0.0.0:6379→6379    2h 15m
prometheus     running   healthy    0.0.0.0:9090→9090    2h 15m
grafana        running   unhealthy  0.0.0.0:3001→3000    2h 15m  ⚠️
alertmanager   exited    —          —                     —       ❌
```

If any service is unhealthy or stopped, automatically fetch its recent logs (last 20 lines) and
include a brief diagnosis.

### 3. Logs

```bash
# Last N lines of a specific service
docker compose -f <file> logs --tail=<N> <service>

# Follow logs in real time (use timeout to avoid hanging)
timeout 30 docker compose -f <file> logs -f <service>

# Filter logs by pattern (pipe through grep)
docker compose -f <file> logs --tail=200 <service> 2>&1 | grep -i "<pattern>"
```

When the user says "docker logs" without specifying a service, show a brief tail (last 10 lines)
of **all** services in the active compose file. If they mention a specific service or error,
filter to that.

Common log-related requests and how to handle them:
- "покажи логи монго" → `docker compose logs --tail=50 mongo`
- "ошибки в бэкенде" → `docker compose -f docker-compose.test.yml logs --tail=200 backend-test 2>&1 | grep -iE 'error|exception|fatal'`
- "что происходит" → health check first, then logs of any unhealthy services

### 4. Volume & Network Management

```bash
# List volumes for this project
docker volume ls --filter "name=my_zodiac"

# Inspect a volume
docker volume inspect <volume_name>

# Clean up test volumes (preserve dev data!)
docker compose -f docker-compose.test.yml down --volumes

# List networks
docker network ls --filter "name=my_zodiac"

# Inspect network (see connected containers)
docker network inspect <network_name>
```

**Safety rule:** Never remove dev volumes (`mongo_data`, `redis_data`, `grafana_data`,
`prometheus_data`) without explicit user confirmation. Test volumes are safe to clean up.

### 5. Diagnostics

When a container won't start or keeps crashing, follow this diagnostic flow:

1. **Check status:** `docker compose -f <file> ps <service>`
2. **Check logs:** `docker compose -f <file> logs --tail=50 <service>`
3. **Check resource usage:** `docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" | grep -i zodiac`
4. **Check config:** `docker compose -f <file> config --services` to verify the compose file parses correctly
5. **Inspect container:** `docker inspect <container_name>` for detailed state, exit code, OOM status

Common issues and their resolution:

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| mongo won't start | Port 27017 in use | `lsof -i :27017` → stop conflicting process |
| redis OOM | maxmemory reached | Check `docker stats`, consider `docker compose restart redis` |
| grafana unhealthy | Port 3000 vs 3001 mapping | Healthcheck uses internal port 3000, external is 3001 — this is normal, check actual response |
| backend-test exits immediately | Missing dependencies | Check if mongo-test and redis-test are healthy first |
| "network not found" | Orphaned resources | `docker compose down --remove-orphans` then `up -d` |
| "port already allocated" | Another compose env running | `docker compose down` the conflicting environment first |

## Output Format

### Terminal Output (always)
Show results directly with clear formatting. Use emoji sparingly for status indicators:
- ✅ healthy/running
- ⚠️ unhealthy/degraded
- ❌ stopped/error

### Markdown Report (when the user asks, or for complex diagnostics)
Save to `docs/reports/docker/` with timestamped filename. Structure:

```markdown
# Docker Health Report — {environment}
**Generated:** {timestamp}

## Summary
{pass/warn/fail counts}

## Services
{detailed per-service table}

## Issues Found
{description and recommended fix for each issue}

## Actions Taken
{what commands were run and their results}
```

## Important Notes

- Always `cd` to the project root before running compose commands. The project root is the directory
  containing `docker-compose.yml`.
- For `front/` compose files, you need to `cd` to the `front/` directory OR use `-f front/docker-compose.*.yml`
  from the project root.
- The test compose file uses **profiles** — services like load-test, chaos-test etc. won't start with
  a plain `docker compose up` unless you specify `--profile`.
- The prod compose file expects `.env.production` and external MongoDB/Redis. Don't try to start it
  in dev without those.
- When running health checks, the compose `ps --format json` may return different JSON structures
  depending on the docker compose version. Handle both v1 (array) and v2 (newline-delimited JSON).
- If `docker` is not available, tell the user and suggest they install Docker Desktop or check their
  PATH.
