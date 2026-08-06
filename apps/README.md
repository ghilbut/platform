---
type: guide
area: apps
---

# Applications

`apps/`는 CPA Argo CD가 관리하는 Kubernetes workload의 진입점이다. CPA Argo CD bootstrap은 [[argo-apps/argo-apps|argo-apps Application]]에서 시작하며, 설치 절차는 [[runbooks/cpa-bootstrap|CPA bootstrap]]을 따른다.

## Bootstrap

CPA K3s 기반 준비는 [[k3s/runbooks/CPA|CPA K3s RUNBOOK]]을 따르고, 그 뒤 Application bootstrap을 실행한다. Application 구성은 `argo-apps/`의 YAML로 관리한다.

Kubernetes workload 보안 기준은 [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)를 따른다.
