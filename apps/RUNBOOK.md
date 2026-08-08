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
| BOOTSTRAP | Archived | [[runbooks/BOOTSTRAP|Bootstrap]] | [`d14b63a`](https://github.com/ghilbut/platform/tree/d14b63a3e59f076afcd1b5e15f2e31ae81800f33/apps) |
| SECURITY | Current | [[runbooks/SECURITY|Security]] |  |

`BOOTSTRAP`은 CPA Argo CD 설치, immutable bootstrap revision 적용, 기반 Application sync와 `main` handoff를 수행하는 복구 문서다. `SECURITY`는 Vault, PostgreSQL, Keycloak, workload 보안과 통합 복구를 진행한다.

## SECURITY 설계

이 절은 `SECURITY` 실행 단계의 재현 기준을 정의한다. 실제 명령은 [[runbooks/SECURITY|Security]]와 각 Application manifest에 둔다.

### 플랫폼 서비스와 런타임

Vault, PostgreSQL과 Keycloak은 전체 플랫폼이 공유하는 논리 서비스다. 서비스의 논리 데이터와 data backup은 특정 Kubernetes 클러스터에 종속하지 않는다. CPA는 현재 런타임이다.

Kubernetes workload, ServiceAccount OIDC trust, storage와 network route는 런타임 자산이다. 런타임을 변경할 때 새 런타임 자산을 만들고 공통 KMS key와 application data backup으로 서비스를 복원한다.

Vault는 Integrated Raft member 한 개로 시작한다. Helm의 HA mode는 Integrated Raft topology와 active service를 선택한다. `replicas: 1`은 node 장애를 견디지 못한다. 한 member에서는 PodDisruptionBudget을 사용하지 않는다. Member를 늘릴 때 서로 다른 node와 storage failure domain을 사용한다.

Application은 Helm chart 또는 배포 artifact version을 고정한다. Chart의 기본 image가 chart `appVersion`과 같으면 기본 image를 사용한다. 별도 image는 호환성과 복구를 검증한 경우에만 지정한다.

### 통신 보안

외부 요청은 Istio gateway에서 HTTPS로 수신한다.

Vault workload에 Istio mTLS가 적용되기 전에는 gateway와 Vault 사이에서도 Vault TLS를 사용한다. 다음 조건을 모두 확인한 뒤 Vault listener를 HTTP로 바꾸고 `tlsDisable: true`를 사용한다.

1. Vault workload가 mesh data plane에 포함된다.
2. Vault namespace에 STRICT mTLS가 적용된다.
3. 필요한 source와 port만 허용하는 Istio AuthorizationPolicy가 적용된다.
4. 외부 HTTPS와 내부 mTLS 경로의 접근 및 복구 검증이 성공한다.

JWT는 bearer JWT를 보내는 요청에만 요구한다. 내부 workload 통신은 Cilium network policy, Istio workload identity 기반 mTLS와 AuthorizationPolicy, Vault 인증을 함께 사용한다.

### Storage와 backup

Stateful Application은 `openebs-lvm-thin`을 사용한다. PVC와 PV는 Application 제거 뒤에도 보존한다.

| 종류 | 목적 | 런타임 종속성 | S3 prefix |
| --- | --- | --- | --- |
| Vault Raft data backup | Vault 논리 데이터 복원 | 없음 | `data/vault/raft/` |
| PostgreSQL physical data backup | base backup과 point-in-time recovery | 없음 | `data/postgresql/barman/` |
| PostgreSQL logical data backup | 새 PostgreSQL에 database 복원 | 없음 | `data/postgresql/dump/` |
| OpenEBS volume snapshot backup | 현재 volume의 빠른 복원 | K3s와 OpenEBS | `snapshots/k3s/cpa/volumes/` |

K3s etcd snapshot은 Kubernetes 런타임 전체를 복원한다. 설정과 절차는 [[k3s/RUNBOOK|K3s 기반 RUNBOOK]]에서 관리한다.

OpenEBS snapshot은 crash-consistent 복구 지점이다. Velero는 snapshot data를 S3로 이동한다. Vault Raft backup과 PostgreSQL backup은 application-consistent 복구 지점이다.

| Backup | 주기 | 보존 |
| --- | --- | --- |
| Vault OpenEBS snapshot | 6시간 | 7일, 최대 28개 |
| Vault Raft data backup | 6시간 | 7일, 최대 28개 |
| PostgreSQL OpenEBS snapshot | 6시간 | 7일, 최대 28개 |
| PostgreSQL logical data backup | 6시간 | 7일, 최대 28개 |
| PostgreSQL Barman base backup | 매일 | 7일 |
| PostgreSQL WAL archive | 연속 | 7일 |

Backup 작업은 서로 겹치지 않게 실행한다. Backup 삭제 권한은 각 작업의 prefix로 제한한다.

### Credential 경계

- Vault KMS key와 application data backup prefix는 플랫폼 공통 자산이다.
- 현재 런타임의 ServiceAccount만 해당 런타임용 IAM role을 수임한다.
- Application workload는 static AWS access key를 사용하지 않는다.
- Vault recovery key는 SecurityTooling AWS Secrets Manager에 KMS 암호화하여 저장한다.
- Initial root token은 초기 설정을 마친 뒤 revoke하고 저장하지 않는다.
- Backup repository를 여는 credential은 Vault 없이 복구할 수 있어야 한다.
- OIDC 장애 복구는 K3s administrator certificate와 Argo CD port-forward를 사용한다.

### 복구 순서

1. K3s etcd snapshot 복원을 시도한다.
2. 실패하면 K3s와 `BOOTSTRAP`부터 Current runbook까지 다시 실행한다.
3. OpenEBS volume snapshot backup으로 빠른 복원을 시도한다.
4. 실패하면 새 volume에 application data backup을 복원한다.
5. Vault, PostgreSQL, Keycloak, OIDC, network policy 순서로 확인한다.
6. 복구에 사용한 Application source revision을 `main`으로 되돌린다.

### OpenTofu와 Git revision

- 정상 Plan과 Apply는 root 전체를 사용한다.
- `-target`은 복구 runbook이 resource address와 종료 조건을 지정한 경우에만 사용한다.
- Targeted Apply 뒤에는 target 없는 전체 Plan을 실행하여 변경 사항이 없어야 한다.
- 모든 Application의 정상 revision은 `main`이다.
- Archive SHA는 복구 중인 Application에만 임시 적용하고 복구가 끝나면 `main`으로 되돌린다.

## Pod Security Standards

![[knowledge/rulebooks/k8s/SECURITY#Pod Security Standards]]
