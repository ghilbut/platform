---
type: guide
area: apps
---

# Applications

`apps/`는 CPA Kubernetes cluster에서 실행되는 애플리케이션의 진입점이다. Argo CD bootstrap은 [argo.yaml](argo.yaml)에서 시작하며, 애플리케이션 문서는 [Applications Documents RULEBOOK](docs/RULEBOOK.md)을 따른다.

## Bootstrap

CPA 초기 설치에서는 [Cilium](argo-apps/cilium.yaml), [Istio system](argo-apps/istio-system.yaml), [Istio gateways](argo-apps/istio-gateways.yaml)를 이 순서로 동기화한다. 각 단계가 Healthy 상태인지 확인한 뒤 다음 단계를 실행한다. ingress gateway가 준비된 뒤에 [cert-manager](argo-apps/cert-manager.yaml)와 [external-dns](argo-apps/external-dns.yaml)를 추가한다. 구체적인 실행과 기존 ApplicationSet 이관 절차는 [Istio RUN-PLAN](docs/istio/RUN-ISTIO-2026-08-02-PLAN.md)을 따른다.

## 문서

| 애플리케이션 | README | RULEBOOK | RUN-PLAN | RUNBOOK | PLAYBOOK |
| --- | --- | --- | --- | --- | --- |
| [Argo CD](argo-apps/argo.yaml) | — | — | — | — | — |
| [Cilium](argo-apps/cilium.yaml) | — | — | — | — | — |
| [OpenEBS](argo-apps/ebs.yaml) | [README](docs/ebs/README.md) | — | — | [RUNBOOK](docs/ebs/RUNBOOK.md) | — |
| [cert-manager](argo-apps/cert-manager.yaml) | [README](docs/cert-manager/README.md) | — | [RUN-PLAN](docs/cert-manager/RUN-CERT-MANAGER-2026-08-02-PLAN.md) | — | — |
| [external-dns](argo-apps/external-dns.yaml) | [README](docs/external-dns/README.md) | — | [RUN-PLAN](docs/external-dns/RUN-EXTERNAL-DNS-2026-08-03-PLAN.md) | — | — |
| [Istio system](argo-apps/istio-system.yaml), [Istio gateways](argo-apps/istio-gateways.yaml) | [README](docs/istio/README.md) | — | [RUN-PLAN](docs/istio/RUN-ISTIO-2026-08-02-PLAN.md) | — | — |
| [Keycloak](argo-apps/keycloak.yaml) | [README](docs/keycloak/README.md) | — | [RUN-PLAN](docs/keycloak/RUN-KEYCLOAK-2026-08-02-PLAN.md) | — | — |
| [Vault](argo-apps/vault.yaml) | [README](docs/vault/README.md) | — | [RUN-PLAN](docs/vault/RUN-VAULT-2026-08-02-PLAN.md) | [RUNBOOK](docs/vault/RUNBOOK.md) | [PLAYBOOK](docs/vault/PLAYBOOK.md) |

Kubernetes workload 보안 기준은 [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)를 따른다.
