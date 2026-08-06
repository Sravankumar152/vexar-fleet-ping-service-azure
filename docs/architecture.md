# Architecture

Proposed Azure architecture for the Fleet Ping Service. Technical clarity is
the goal; the diagram renders on GitHub (Mermaid).

```mermaid
flowchart TB
    subgraph Clients
        V["Fleet vehicles / driver app<br/>(HTTPS pings + login)"]
    end

    subgraph GitHub["GitHub"]
        REPO["Repo"]
        CI["Actions CI/CD<br/>test → scan → build → deploy → verify"]
    end

    subgraph Azure["Azure Subscription"]
        subgraph Edge["Public edge"]
            ING["AKS Ingress<br/>(App Routing + TLS)"]
        end

        subgraph VNet["Virtual Network (private)"]
            subgraph AKS["AKS cluster (private nodes)"]
                POD["fleet-ping pods<br/>(HPA, non-root)<br/>SA + Workload Identity"]
                CSI["Key Vault CSI driver"]
            end
            PG[("Azure DB for PostgreSQL<br/>Flexible Server + PgBouncer<br/>private, TLS, PITR/HA")]
        end

        KV["Key Vault<br/>(db + jwt secrets)"]
        ACR["Container Registry"]
        MON["Azure Monitor +<br/>Log Analytics / Container Insights"]
        AAD["Entra ID (AAD)<br/>Managed Identities + RBAC"]
    end

    V -->|HTTPS| ING --> POD
    POD -->|"pooled, TLS"| PG
    POD --- CSI
    CSI -->|"Workload Identity<br/>(no stored secret)"| KV
    POD -->|pull image| ACR

    REPO --> CI
    CI -->|"OIDC (no secrets)"| AAD
    CI -->|push image by SHA| ACR
    CI -->|"helm upgrade"| POD

    POD -.logs/metrics.-> MON
    PG -.metrics/alerts.-> MON
    AKS -.->|AcrPull| ACR
    AAD -. issues tokens .-> POD
    AAD -. authorizes .-> KV

    classDef public fill:#fde,stroke:#c69;
    classDef private fill:#def,stroke:#69c;
    class ING public;
    class AKS,PG,VNet private;
```

## Network boundaries

- **Public:** only the AKS ingress (HTTPS/TLS). Everything else is private.
- **Private (VNet-only):** AKS nodes/API server (prod), PostgreSQL (VNet
  integrated, no public endpoint), Key Vault + ACR (private endpoints in prod).
- **No inbound to the database** from the internet; the app reaches it over the
  VNet through PgBouncer.

## Trust / identity

- Pods authenticate to Azure via **Workload Identity** (federated OIDC) — no
  client secrets in the cluster.
- CI authenticates via **GitHub OIDC** federation — no stored cloud creds.
- Secrets live in **Key Vault**, pulled at runtime via the **CSI driver**;
  never in git or images.
```
