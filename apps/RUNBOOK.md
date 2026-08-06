---
type: runbook
area: apps
cluster: cpa
---

# CPA Applications RUNBOOK

## 목표

CPA Argo CD가 CPA와 이후 등록하는 클러스터의 desired state를 관리한다. [Argo CD](https://argo.ghilbut.com/cd)는 CPA 관리 endpoint다.

```text
CPA K3s → CPA Argo CD → CPA와 GPA의 Application
```

## K3s 의존성

[[k3s/runbooks/CPA|CPA K3s 기반 준비]]가 다음 상태를 준비한 뒤 Application bootstrap을 시작한다.

- `cpa` Kubernetes context
- Ready Cilium node
- OpenEBS LVM volume group
- 공개 ServiceAccount OIDC issuer

K3s는 workload를 설치하지 않는다. CPA Argo CD와 모든 Kubernetes workload는 이 영역에서 관리한다.

## GitOps 경계

- `argo-apps`는 child Application만 생성한다.
- `argo-apps`를 수동 sync하지 않는다.
- bootstrap은 검증된 tag와 commit SHA의 `argo-apps`에서 시작한다.
- bootstrap 완료 후 `argo-apps`는 `main`의 Application 선언을 추적한다.
- child Application은 명시적으로 선택 sync한다.
- `argo` Application은 전체 sync하지 않는다. Argo route는 `routes.yml` VirtualService만 sync한다.

## 실행 문서

| 단계 | 상태 | 실행 문서 | Archive SHA |
| --- | --- | --- | --- |
| BOOTSTRAP | Current | [[runbooks/BOOTSTRAP|Bootstrap]] |  |

`BOOTSTRAP`은 CPA Argo CD 설치, immutable bootstrap revision 적용, 기반 Application sync와 `main` handoff를 수행한다.

## Pod Security Standards

![[knowledge/rulebooks/k8s/SECURITY#Pod Security Standards]]
