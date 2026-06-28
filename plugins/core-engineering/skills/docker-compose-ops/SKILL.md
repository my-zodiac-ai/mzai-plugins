---
name: docker-compose-ops
description: >
  Use this skill for ANY task involving Docker containers, docker compose, or local infrastructure
  services (databases, caches, metrics stacks). Covers: starting/stopping dev, test, e2e, or prod
  environments; checking container status, health, or resource usage (memory, CPU); viewing or filtering
  container logs; diagnosing why a service crashes, restarts, or won't start (port conflicts, OOM,
  missing deps); managing volumes and networks; running e2e or integration tests that live in
  docker-compose files. Trigger even when Docker isn't explicitly mentioned — if the user wants to
  "поднять дев", check what's running, debug a restarting redis/mongo, see container memory usage,
  or run e2e tests from compose, this is the right skill.
x-scope: core
x-stack: any
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---

# Docker Compose Operations

Operations assistant for any repo that uses Docker Compose. Execute docker compose commands directly
and present results clearly — both as terminal output and, when appropriate, as a structured markdown
report. Nothing here is stack-specific: it works for any compose project.

## Discover the project's compose setup first

Don't assume file names. Detect them:

```bash
# Find every compose file in the repo
find . -maxdepth 3 -name 'docker-compose*.y*ml' -not -path '*/node_modules/*'
# Validate a file parses and list its services
docker compose -f <file> config --services
# List profiles a file defines (services gated behind --profile)
docker compose -f <file> config --profiles
```

Map the user's casual intent to a file: **dev / разработка / поднять дев / default** → the root
`docker-compose.yml`; **prod / продакшн** → the `*.prod.yml`; **test / тесты** → the `*.test.yml`;
**e2e / playwright** → the e2e compose file. When unspecified, default to **dev**.

## Core operations (stack-agnostic)

### 1. Start / Stop / Restart
Always print the command before running it — builds trust and aids debugging.

```bash
docker compose -f <file> up -d [service...]
docker compose -f <file> down [--volumes] [--remove-orphans]
docker compose -f <file> restart <service>
```

If a compose file uses **profiles**, services gated behind them won't start with a plain `up` —
add `--profile <name>` (discover names with `config --profiles`).

### 2. Health check (most common)
1. `docker compose -f <file> ps --format json` for container states.
2. Per running container: `docker inspect --format='{{json .State.Health}}' <container>`.
3. Read port bindings from `ps` output.
4. Present a summary table:

```
Service        Status    Health     Ports                 Uptime
────────────────────────────────────────────────────────────────
db             running   healthy    0.0.0.0:5432→5432     2h 15m
cache          running   healthy    0.0.0.0:6379→6379     2h 15m
metrics        running   unhealthy  0.0.0.0:9090→9090     2h 15m  ⚠️
```

If any service is unhealthy/stopped, automatically fetch its recent logs (last 20 lines) and add a
brief diagnosis. Note: `ps --format json` differs between compose v1 (array) and v2 (newline-delimited
JSON) — handle both.

### 3. Logs
```bash
docker compose -f <file> logs --tail=<N> <service>
timeout 30 docker compose -f <file> logs -f <service>          # follow, with timeout so it can't hang
docker compose -f <file> logs --tail=200 <service> 2>&1 | grep -iE 'error|exception|fatal'
```
When the user says "logs" without a service, show a short tail of all services in the active file;
if they name a service or error, filter to it.

### 4. Volumes & networks
```bash
# Scope to this project (compose prefixes resources with the project name / dir basename)
proj="$(basename "$PWD")"
docker volume ls  --filter "name=${proj}"
docker network ls --filter "name=${proj}"
docker volume inspect <volume>; docker network inspect <network>
```
**Safety rule:** never remove dev data volumes without explicit confirmation. Test volumes
(`docker compose -f <test-file> down --volumes`) are safe to clean.

### 5. Diagnostics (won't start / keeps crashing)
1. `docker compose -f <file> ps <service>`
2. `docker compose -f <file> logs --tail=50 <service>`
3. `docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"`
4. `docker compose -f <file> config --services` (confirm the file parses)
5. `docker inspect <container>` (exit code, OOMKilled, restart count)

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| DB won't start | Port in use | `lsof -i :<port>` → stop the conflicting process |
| Cache OOM | maxmemory reached | check `docker stats`; restart or raise the limit |
| Service exits immediately | Dependency not healthy | confirm its `depends_on` services are healthy first |
| "network not found" | Orphaned resources | `docker compose down --remove-orphans` then `up -d` |
| "port already allocated" | Another compose env running | `down` the conflicting environment first |

## Output format
- **Terminal (always):** direct, clear; status emoji sparingly — ✅ healthy, ⚠️ degraded, ❌ stopped.
- **Markdown report (on request / complex diagnostics):** save to `docs/reports/docker/` with a
  timestamped filename — Summary (pass/warn/fail counts) → Services table → Issues + fixes → Actions taken.

## Rules
- Always `cd` to the directory containing the target compose file (or use `-f <path>`).
- Profile-gated services need `--profile`.
- Prod compose files usually expect a `.env.production` + external managed services — don't start them in dev.
- If `docker` is unavailable, say so and suggest installing Docker Desktop / checking PATH.

## Example: a monorepo with dev / test / e2e environments

A real layout this skill was extracted from (My Zodiac AI) — illustrative only; detect the actual
files per the discovery step above:

| File | Env | Default services |
|------|-----|------------------|
| `docker-compose.yml` (root) | dev | mongo, redis, prometheus, alertmanager, grafana |
| `docker-compose.prod.yml` (root) | prod | backend, prometheus, alertmanager, grafana |
| `docker-compose.test.yml` (root) | test | mongo-test, redis-test, backend-test + profiles: load, chaos, validation, memory, features, frontend, lighthouse |
| `front/docker-compose.e2e.yml` | e2e | mongodb-test, redis-test, backend-test, frontend-test, playwright |

Profiles in that test file: `load`→load-test, `chaos`→chaos-test, `validation`→release-validation,
`memory`→memory-test, `features`→feature-flag-test, `frontend`→frontend-test, `lighthouse`→lighthouse.
Dev data volumes to protect: `mongo_data`, `redis_data`, `grafana_data`, `prometheus_data`.
For `front/` compose files, `cd front/` or use `-f front/docker-compose.*.yml` from the root.
