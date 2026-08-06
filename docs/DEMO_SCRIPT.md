# Demo video script (~5–7 minutes)

A running order for the submission video. The graders care about *why*, so
narrate decisions, not just clicks. Since a live Azure deploy is optional, this
script demos the app **locally** plus `terraform validate` / `helm lint` — which
the brief explicitly accepts in place of a live deployment.

---

## Before you record (one-time setup)

```bash
cd devops-assessment

# 1. Generate + commit the lockfile (needed for the Docker build's npm ci).
npm install

# 2. Bring up the stack (app + postgres); migrations run automatically.
docker compose up --build -d

# 3. Seed a demo driver so login succeeds.
docker compose exec -T db psql -U fleet_app -d vexar_fleet < db/seed.sql

# 4. Confirm it's healthy.
curl -s localhost:3000/healthz | jq
curl -s localhost:3000/readyz  | jq
```

Optional (for the IaC part): `az login` not required — just have Terraform and
Helm installed to run `validate` / `lint`.

Screen recording on macOS: **⌘ + Shift + 5**, or QuickTime → File → New Screen
Recording. Record at 1080p and zoom your editor/terminal font.

---

## 1. Intro (30s)
"Inherited Fleet Ping Service — Node/Express + PostgreSQL. I took it to
production-ready on Azure/AKS." State the headline risks.

## 2. The original problems (60s)
`git log --oneline`, then open the ORIGINAL files from history:
```bash
git show b38b522:server.js        # hardcoded creds, SQL injection, open admin
git show b38b522:Dockerfile        # node:latest, root, EXPOSE 22
git show b38b522:docker-compose.yml # committed prod-looking DB password
```

## 3. Application fixes + live run (2 min)
- Walk `src/`: config from env, parameterised queries, OTP verify,
  `requireAuth`/`requireRole`, pg Pool, `/healthz` vs `/readyz`, graceful
  shutdown, pino logging.
- Demo the real flow (copy/paste live):

```bash
# request an OTP
curl -s -X POST localhost:3000/api/auth/request-otp \
  -H 'content-type: application/json' \
  -d '{"phone":"+15551234567"}'

# the OTP is printed in the app logs (dev only)
docker compose logs app | grep "DEV OTP" | tail -1

# log in with that OTP -> returns a JWT
curl -s -X POST localhost:3000/api/auth/login \
  -H 'content-type: application/json' \
  -d '{"phone":"+15551234567","otp":"<OTP_FROM_LOGS>"}'

TOKEN=<paste-token>

# authenticated ping -> 202
curl -s -X POST localhost:3000/api/fleet/ping \
  -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' \
  -d '{"vehicleId":"V1","lat":12.34,"lng":56.78,"speed":40}'

# admin route rejects a non-admin token -> 403 (was open before)
curl -s -o /dev/null -w "%{http_code}\n" localhost:3000/api/admin/drivers \
  -H "authorization: Bearer $TOKEN"

# SQL-injection attempt is rejected at validation -> 400
curl -s -o /dev/null -w "%{http_code}\n" -X POST localhost:3000/api/auth/login \
  -H 'content-type: application/json' -d '{"phone":"'"'"' OR 1=1","otp":"123456"}'
```
- `npm test` — show the suites pass.

## 4. Containerization (30s)
Walk the multi-stage Dockerfile: pinned alpine, non-root, tini, healthcheck,
no SSH. Mention `.dockerignore`. `docker images` to show the size.

## 5. Infrastructure (90s)
- `terraform/` layout (modules + dev/prod). Explain AKS cost-efficiency choices
  and the private PostgreSQL + Key Vault + Workload Identity model.
```bash
cd terraform/envs/dev && terraform init -backend=false && terraform validate
helm lint ../../../k8s/fleet-ping -f ../../../k8s/fleet-ping/values-dev.yaml
```
- Open `docs/architecture.svg`; trace a ping request and a secret fetch.

## 6. CI/CD (45s)
`.github/workflows/ci.yml` + `cd.yml`: Test → Scan → Build(SHA) → Deploy dev →
Verify → prod approval → Deploy prod → Verify; OIDC auth; rollback. If you've
pushed, show a run in the **Actions** tab.

## 7. Monitoring + wrap (30s)
Metric alerts (PG CPU/storage/connections), Container Insights, health probes.
Close with top trade-offs (AKS vs Container Apps) and "what I'd do next."

---

## Teardown
```bash
docker compose down -v
```

## Tip
If you did not deploy live, say so on camera and show `terraform validate` +
`helm lint` — the brief allows this.
