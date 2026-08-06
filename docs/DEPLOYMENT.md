# Deployment runbook

End-to-end steps to stand the service up on Azure. A live deployment is **not**
required by the assessment — this runbook makes it turnkey if/when you choose
to deploy. Everything runs from a workstation with `az`, `terraform`, `kubectl`
and `helm`, signed in to your subscription (`az login`).

## 0. One-time bootstrap

```bash
# Remote state storage (once per org). Names must be globally unique.
az group create -n rg-tfstate -l eastus
az storage account create -n <stunique> -g rg-tfstate -l eastus --sku Standard_LRS \
  --min-tls-version TLS1_2 --allow-blob-public-access false
az storage container create -n tfstate --account-name <stunique>
```

Create a GitHub OIDC identity for CI and grant it `AcrPush` + AKS deploy roles
(federated credential subject = your repo/environment). Store its client/tenant/
subscription IDs as GitHub secrets (see `.github/workflows/README.md`).

## 1. Provision infrastructure (per environment)

```bash
cd terraform/envs/dev            # or envs/prod
cp terraform.tfvars.example terraform.tfvars   # fill unique names, no secrets
export ARM_SUBSCRIPTION_ID=<sub-id>

terraform init \
  -backend-config="resource_group_name=rg-tfstate" \
  -backend-config="storage_account_name=<stunique>" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=fleet-dev.tfstate"

terraform fmt -check && terraform validate
terraform plan -out tfplan
terraform apply tfplan
```

Terraform generates the DB password + JWT secret and stores them in Key Vault.
Capture outputs (used to wire CI + Helm):

```bash
terraform output      # acr_login_server, aks_cluster_name, key_vault_uri,
                      # postgres_fqdn, app_identity_client_id, resource_group_name
```

## 2. Database schema

Run migrations against the new database (as a one-off Job or locally through a
jump host / `az` tunnel, using the admin connection string from Key Vault):

```bash
DATABASE_URL="$(az keyvault secret show --vault-name <kv> -n db-connection-string --query value -o tsv)" \
  npm run db:migrate
# then create the least-privilege role:
psql "<admin conn>" -v app_password="$(az keyvault secret show ... -o tsv)" -f db/roles/app_role.sql
```

## 3. Configure CI environments

In GitHub → Settings → Environments, create `dev` and `prod` (add required
reviewers on `prod`). Set the environment variables and secrets from the
Terraform outputs (table in `.github/workflows/README.md`).

## 4. Deploy the app

Push to `main` → `cd.yml` builds, scans, pushes by SHA, deploys to dev,
verifies, waits for prod approval, then deploys prod. Or manually:

```bash
az aks get-credentials -g <rg> -n <aks_cluster_name>
helm upgrade --install fleet-ping ./k8s/fleet-ping \
  --namespace fleet --create-namespace \
  -f ./k8s/fleet-ping/values-dev.yaml \
  --set image.repository=<acr_login_server>/fleet-ping \
  --set image.tag=<git-sha> \
  --set serviceAccount.workloadIdentityClientId=<app_identity_client_id> \
  --set keyVault.name=<kv-name> \
  --set keyVault.tenantId=<tenant-id> \
  --wait
```

## 5. Verify

```bash
kubectl -n fleet rollout status deployment/fleet-ping
kubectl -n fleet get pods,hpa
kubectl -n fleet run smoke --rm -it --image=curlimages/curl -- \
  curl -fsS http://fleet-ping/readyz
```

## Rollback

```bash
helm -n fleet history fleet-ping
helm -n fleet rollback fleet-ping <previous-revision>
```
