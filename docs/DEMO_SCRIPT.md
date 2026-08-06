# Demo video script (~5–7 minutes)

A suggested running order for the submission video. Keep it tight; the graders
care about *why*, so narrate decisions, not just clicks.

## 1. Intro (30s)
- "Inherited Fleet Ping Service — Node/Express + PostgreSQL. I took it to
  production-ready on Azure/AKS." State the headline risks you found.

## 2. The original problems (60s)
- Show `git log` and the first commits. Open the original `server.js` from
  history: hardcoded DB creds + JWT secret, SQL-injection login, unauthenticated
  admin endpoint, new DB client per request.
- Show the original Dockerfile (`node:latest`, root, `EXPOSE 22`) and the
  committed DB password in `docker-compose.yml`.

## 3. Application fixes (90s)
- `src/` structure. Highlight: config from env, parameterised queries, OTP
  verification, `requireAuth`/`requireRole`, pg Pool, `/healthz` vs `/readyz`,
  graceful shutdown, pino logging with redaction.
- `docker compose up --build`; hit `/healthz`, request an OTP (show it logged in
  dev), log in, POST a ping with the JWT, show 401 on the admin route.
- `npm test` green.

## 4. Containerization (30s)
- Walk the multi-stage Dockerfile: pinned alpine, non-root, tini, healthcheck,
  no SSH. Mention image size + `.dockerignore`.

## 5. Infrastructure (90s)
- `terraform/` layout: modules + dev/prod roots. Explain AKS-cost-efficiency
  choices and the private PostgreSQL + Key Vault + Workload Identity model.
- `terraform validate` (and `plan` if you have a subscription).
- Open the architecture diagram; trace a ping request and a secret fetch.

## 6. CI/CD (60s)
- `ci.yml` + `cd.yml`: Test → Scan → Build(SHA) → Deploy dev → Verify →
  approval → Deploy prod → Verify, OIDC auth, rollback. Show a pipeline run if
  available.

## 7. Monitoring + wrap (45s)
- Metrics/alerts (PG CPU/storage/connections), Container Insights, health
  probes. Close with top trade-offs and "what I'd do next."

## Tips
- If you did not deploy live, say so and show `terraform validate` + `helm lint`
  instead — the brief allows this.
- Record at 1080p; zoom your editor/terminal font.
