# Kubernetes deployment (Helm)

Helm chart that runs the Fleet Ping Service on AKS. It is intentionally thin:
the cluster, database, Key Vault, identity and networking are all provisioned
by Terraform (`../terraform`). This chart only describes the workload.

## How it fits together

- **Workload Identity** — the `ServiceAccount` is annotated with the app
  managed identity's client ID (Terraform output `app_identity_client_id`).
  The pod exchanges its projected token for an AAD token; no client secret.
- **Secrets** — `SecretProviderClass` pulls `db-connection-string` and
  `jwt-secret` from Key Vault through the CSI driver and syncs them into a
  Kubernetes Secret, exposed to the container as `DATABASE_URL` / `JWT_SECRET`.
  Nothing secret is stored in the chart or the image.
- **Health** — liveness hits `/healthz`, readiness hits `/readyz` (readiness
  fails when the database is unreachable, so unready pods leave the LB).
- **Scaling** — HPA on CPU; `maxUnavailable: 0` rolling updates and a
  PodDisruptionBudget keep capacity during deploys and node drains.
- **Security** — non-root, read-only root filesystem, all capabilities
  dropped, `RuntimeDefault` seccomp.

## Deploy

Values that come from Terraform outputs are passed at release time by CI (see
`.github/workflows`). Manually:

```bash
helm upgrade --install fleet-ping ./fleet-ping \
  --namespace fleet --create-namespace \
  -f ./fleet-ping/values-prod.yaml \
  --set image.repository=$ACR_LOGIN_SERVER/fleet-ping \
  --set image.tag=$GIT_SHA \
  --set serviceAccount.workloadIdentityClientId=$APP_IDENTITY_CLIENT_ID \
  --set keyVault.name=$KEY_VAULT_NAME \
  --set keyVault.tenantId=$TENANT_ID
```

The namespace (`fleet`) and SA name (`fleet-ping`) must match the federated
identity credential subject configured in Terraform.
