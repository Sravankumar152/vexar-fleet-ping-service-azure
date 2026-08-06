# CI/CD

Two workflows implement the pipeline
**Test → Build → Security Scan → Containerize → Deploy → Verify**.

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `ci.yml` | PRs to `main`, feature-branch pushes | Test, security scan, build image (no push), Helm lint. Gate for merging. |
| `cd.yml` | Push to `main` | Build + scan + push image, deploy dev → verify → **approve** → deploy prod → verify, with auto-rollback. |

## Pipeline stages

1. **Test** — `npm ci` + `npm test` (+ lint if configured).
2. **Security scan** — `gitleaks` (secrets), `npm audit` (dependency CVEs),
   Trivy filesystem scan (deps + IaC misconfig + secrets). The image is Trivy-
   scanned **before** it is pushed, so a HIGH/CRITICAL image never reaches ACR.
3. **Containerize** — Buildx build, tagged with the **immutable git SHA**
   (never `latest` for deploys) and pushed to ACR.
4. **Deploy** — Helm to AKS, dev first (automatic), then prod (gated).
5. **Verify** — `kubectl rollout status` plus an in-cluster `/readyz` smoke
   test against the Service.

## How the design meets the brief

- **Multiple environments** — separate `dev` and `prod` GitHub Environments,
  each with its own cluster/RG/Key Vault variables; the same image SHA is
  promoted from dev to prod (via `az acr import`) so prod runs exactly what
  dev validated.
- **Production release controls / approval gate** — the `prod` Environment has
  a *required reviewers* protection rule, so `deploy-prod` pauses for a manual
  approval. Restrict who can approve and, optionally, add a wait timer.
- **Environment-specific configuration** — non-secret config via Helm
  `values-<env>.yaml`; secret values pulled at runtime from Key Vault (never
  in CI logs or the image). Cluster/identity coordinates come from GitHub
  Environment variables.
- **Failed deployments / rollback** — `helm upgrade --wait` fails the job if
  pods don't become healthy; a `failure()` step runs `helm rollback` to the
  previous good revision. Because deploys are immutable SHAs, rollback is
  deterministic.

## Auth — no stored cloud credentials

Azure access uses **OIDC federation** (`azure/login`): GitHub mints a
short-lived token, exchanged for an AAD token via a federated credential on a
CI managed identity/app registration. No client secrets or ACR passwords are
stored (unlike the original workflow, which used a static `ACR_PASSWORD`).

## Required configuration

Create a federated credential for GitHub OIDC and grant the CI identity
`AcrPush` on ACR and `Azure Kubernetes Service Cluster User` + deploy rights on
the clusters. Then set:

**Repository / Environment secrets**

| Name | Notes |
|------|-------|
| `AZURE_CLIENT_ID` | CI app/identity client ID |
| `AZURE_TENANT_ID` | AAD tenant ID (also used as Key Vault tenant) |
| `AZURE_SUBSCRIPTION_ID` | Target subscription |

**Environment variables (per `dev` / `prod`)**

| Name | Example |
|------|---------|
| `ACR_NAME` | `vexarfleetprodacr` |
| `ACR_LOGIN_SERVER` | `vexarfleetprodacr.azurecr.io` |
| `RESOURCE_GROUP` | `rg-vexar-fleet-prod` |
| `AKS_CLUSTER_NAME` | `aks-vexar-fleet-prod` |
| `KEY_VAULT_NAME` | `kv-vexar-fleet-prod` |
| `APP_IDENTITY_CLIENT_ID` | Terraform output `app_identity_client_id` |

> Values map 1:1 to Terraform outputs, so wiring CI after `terraform apply`
> is a copy-paste.
