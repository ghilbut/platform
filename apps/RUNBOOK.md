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

## CPA 복구

CPA를 리셋한 뒤 [[k3s/runbooks/CPA-RESTORE|K3s snapshot 복원]]을 먼저 실행한다.

Snapshot 복원이 성공하면 Applications `BOOTSTRAP`을 실행하지 않는다. 복원된 Argo CD와
Application을 확인한 뒤 각 애플리케이션의 S3 백업에서 데이터를 복원한다.

Snapshot 복원이 실패하면 다음 순서로 대체 복구를 실행한다.

1. 실패한 상태에서 cluster reset과 Applications `BOOTSTRAP`을 실행하지 않는다.
2. [[k3s/runbooks/CPA#C. K3s server|CPA K3s server]]부터 Cilium까지 다시 준비한다.
3. 아래 표의 `BOOTSTRAP`부터 `Current` 단계까지 순서대로 실행한다.
4. 각 애플리케이션 설치를 확인한 뒤 해당 애플리케이션의 S3 백업에서 데이터를 복원한다.

Archive SHA는 runbook을 Archive한 시점의 platform GitOps 설정 원본을 가리킨다. Archived
단계를 복구할 때 해당 단계가 지정하는 Application의 platform Git source revision을 `main`에서
Archive SHA로 임시 override한다. 단계 복구를 마치면 revision을 `main`으로 되돌린다. Git branch와
파일은 변경하지 않는다.

애플리케이션 데이터 백업은 Archive SHA와 별도로 관리한다. Archive 표에는 데이터 백업 정보를
기록하지 않는다.

## GitOps 경계

- `argo-apps`는 child Application만 생성한다.
- `argo-apps`를 수동 sync하지 않는다.
- bootstrap은 검증된 tag와 commit SHA의 `argo-apps`에서 시작한다.
- bootstrap 완료 후 모든 Application의 platform Git source는 `main`을 추적한다.
- Archive SHA는 복구 중인 Application의 platform Git source에만 임시 적용한다.
- child Application은 명시적으로 선택 sync한다.
- `argo` Application은 전체 sync하지 않는다. Argo route는 `routes.yml` VirtualService만 sync한다.

## 실행 문서

| 단계 | 상태 | 실행 문서 | Archive SHA |
| --- | --- | --- | --- |
| BOOTSTRAP | Current | [[runbooks/BOOTSTRAP|Bootstrap]] |  |

`BOOTSTRAP`은 CPA Argo CD 설치, immutable bootstrap revision 적용, 기반 Application sync와 `main` handoff를 수행한다.

## Pod Security Standards

![[knowledge/rulebooks/k8s/SECURITY#Pod Security Standards]]
