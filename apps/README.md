---
type: guide
area: apps
---

# Applications

`apps/`는 CPA Kubernetes cluster에서 실행되는 애플리케이션의 진입점이다. Argo CD bootstrap은 [argo.yaml](argo.yaml)에서 시작하며, 애플리케이션 문서는 [Applications Documents RULEBOOK](docs/RULEBOOK.md)을 따른다.

## 문서

| 애플리케이션 | README | RULEBOOK | RUN-PLAN | RUNBOOK | PLAYBOOK |
| --- | --- | --- | --- | --- | --- |
| [Argo CD](argo-apps/argo.yaml) | — | — | — | — | — |
| [Cilium](argo-apps/cilium.yaml) | — | — | — | — | — |
| [OpenEBS](argo-apps/ebs.yaml) | — | — | — | — | — |
| [cert-manager](argo-apps/cert-manager.yaml) | — | — | — | — | — |
| [external-dns](argo-apps/external-dns.yaml) | — | — | — | — | — |
| [Istio](argo-apps/istio.yaml) | — | — | — | — | — |
| [Keycloak](argo-apps/keycloak.yaml) | [README](docs/keycloak/README.md) | — | [RUN-PLAN](docs/keycloak/RUN-KEYCLOAK-2026-08-02-PLAN.md) | — | — |
| [Vault](argo-apps/vault.yaml) | [README](docs/vault/README.md) | — | [RUN-PLAN](docs/vault/RUN-VAULT-2026-08-02-PLAN.md) | [RUNBOOK](docs/vault/RUNBOOK.md) | [PLAYBOOK](docs/vault/PLAYBOOK.md) |

Kubernetes workload 보안 기준은 [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)를 따른다.
