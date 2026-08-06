# VexarDrive Fleet Ping Service

A Node.js/Express backend that ingests vehicle location pings and handles driver
authentication, backed by PostgreSQL and designed to run on **Azure Kubernetes
Service (AKS)**.

This repository is a response to the VexarDrive DevOps & Cloud Infrastructure
Engineer technical assessment: an inherited, deliberately-flawed service taken
to a production-ready state. See [`docs/TECHNICAL_REPORT.md`](docs/TECHNICAL_REPORT.md)
for the full write-up of what was found, what changed, and why.

## What's here

```
.
├── server.js               # process entry point (graceful shutdown)
├── src/                    # application (config, logging, db pool, auth,
│                           #   otp, validation, routes)
├── tests/                  # jest + supertest suites
├── db/                     # SQL migrations, least-privilege role, runner input
├── scripts/migrate.js      # transactional migration runner
├── Dockerfile              # multi-stage, non-root, healthchecked image
├── docker-compose.yml      # local dev stack (app + postgres)
├── terraform/              # Azure IaC (AKS, PostgreSQL, Key Vault, ACR, ...)
├── k8s/fleet-ping/         # Helm chart (workload identity, CSI secrets, HPA)
├── .github/workflows/      # CI + CD pipelines
└── docs/                   # technical report, architecture diagram, demo script
```

## API

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| GET | `/healthz` | none | Liveness (process up). |
| GET | `/readyz` | none | Readiness (DB reachable). |
| POST | `/api/auth/request-otp` | none | Issue a login OTP for a phone. |
| POST | `/api/auth/login` | none | Verify OTP → JWT. |
| POST | `/api/fleet/ping` | Bearer JWT | Ingest a vehicle location ping. |
| GET | `/api/admin/drivers` | Bearer JWT (admin) | Paginated driver listing. |

## Run locally

```bash
cp .env.example .env         # adjust if needed (safe local defaults exist)
docker compose up --build    # app on http://127.0.0.1:3000, migrations auto-run
```

Or without Docker:

```bash
npm install                  # also generates package-lock.json (commit it!)
npm run db:migrate
npm run dev
```

Test / lint:

```bash
npm test
npm run lint
```

> **Important:** commit `package-lock.json`. The Dockerfile and CI use
> `npm ci`, which requires the lockfile for reproducible, auditable installs.

## Deploy to Azure

Infrastructure and app deployment are code. A live deployment is **not**
required by the assessment; see the deploy runbook in
[`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md) and the reasoning in the technical
report.

## AI tool usage

Per the assessment rules, AI assistance (Claude) was used; the scope is
disclosed in the technical report.
