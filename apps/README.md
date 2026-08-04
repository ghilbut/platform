---
type: guide
area: apps
---

# Applications

`apps/`는 CPA Kubernetes cluster에서 실행되는 애플리케이션의 진입점이다. Argo CD bootstrap은 [[argo-apps/argo-apps|argo-apps Application]]에서 시작하며, 설치 절차는 [[RUNBOOK]]을 따른다.

## Bootstrap

CPA 초기 설치 순서는 [[RUNBOOK#B. 설치 순서]]를 따른다. `apps/docs/`는 참고 자료로만 사용한다.

## 문서

| 애플리케이션 | README | RULEBOOK | RUN-PLAN | RUNBOOK | PLAYBOOK |
| --- | --- | --- | --- | --- | --- |
| [Argo CD](argo-apps/argo.yaml) | — | — | — | — | — |
| [Cilium](argo-apps/cilium.yaml) | — | — | — | — | — |
| [OpenEBS](argo-apps/ebs.yaml) | — | — | — | — | — |
| [cert-manager](argo-apps/cert-manager.yaml) | [README](docs/cert-manager/README.md) | — | [RUN-PLAN](docs/cert-manager/RUN-CERT-MANAGER-2026-08-02-PLAN.md) | — | — |
| [external-dns](argo-apps/external-dns.yaml) | [README](docs/external-dns/README.md) | — | [RUN-PLAN](docs/external-dns/RUN-EXTERNAL-DNS-2026-08-03-PLAN.md) | — | — |
| [Istio system](argo-apps/istio-system.yaml), [Istio gateways](argo-apps/istio-gateways.yaml) | [README](docs/istio/README.md) | — | [RUN-PLAN](docs/istio/RUN-ISTIO-2026-08-02-PLAN.md) | — | — |
| [Keycloak](argo-apps/keycloak.yaml) | [README](docs/keycloak/README.md) | — | — | — | — |

Kubernetes workload 보안 기준은 [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)를 따른다.
