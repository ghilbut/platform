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

이 절은 `SECURITY` 실행 단계의 재현 기준과 구현 계획을 정의한다. 실제 설치와 복구 명령은 [[runbooks/SECURITY|Security]]와 각 실행 Issue에서 완성한다.

### 플랫폼 서비스와 런타임

Vault, PostgreSQL과 Keycloak은 전체 플랫폼이 공유하는 논리 서비스다. 서비스의 논리 데이터와 data backup은 특정 Kubernetes 클러스터에 종속하지 않는다. CPA는 현재 런타임이다.

Kubernetes workload, ServiceAccount OIDC trust, storage와 network route는 런타임 자산이다. 런타임을 변경할 때 새 런타임 자산을 만들고 공통 KMS key와 application data backup으로 서비스를 복원한다.

Vault는 Integrated Raft member 한 개로 시작한다. Helm의 HA mode는 Integrated Raft topology와 active service를 선택한다. `replicas: 1`은 node 장애를 견디지 못한다. 한 member에서는 PodDisruptionBudget을 사용하지 않는다. Member를 늘릴 때 서로 다른 node와 storage failure domain을 사용한다.

Application은 Helm chart 또는 배포 artifact version을 고정한다. Chart의 기본 image가 chart `appVersion`과 같으면 기본 image를 사용한다. 별도 image는 호환성과 복구를 검증한 경우에만 지정한다.

### 실행 환경과 storage

CPA는 단일 K3s server와 단일 OpenEBS LVM volume group을 사용한다. Vault, PostgreSQL과 Keycloak은 각각 replica 한 개로 시작한다. K3s snapshot과 S3 backup이 node 장애 복구를 담당한다.

K3s host는 `dm_snapshot`과 `dm_thin_pool` kernel module을 부팅할 때 로드한다. [[k3s/RUNBOOK#1. host 준비|K3s host 준비]]에서 두 module과 device mapper target을 확인한 뒤 OpenEBS thin volume을 사용한다.

Stateful Application은 `openebs-lvm-thin` StorageClass를 사용한다. OpenEBS LocalPV LVM의 snapshot restore는 thin volume을 사용한다. PVC와 PV는 Application 제거 뒤에도 보존한다. Velero가 S3 data movement를 마치면 임시 OpenEBS snapshot을 제거한다.

### 제품 선택

| 책임 | 제품 |
| --- | --- |
| Local volume과 snapshot | OpenEBS LVM LocalPV |
| Snapshot S3 data movement | Velero CSI Snapshot Data Movement와 Kopia |
| Secret store | Vault Integrated Raft |
| Secret delivery | Vault Secrets Operator |
| PostgreSQL 운영 | CloudNativePG |
| PostgreSQL physical backup | Barman Cloud Plugin |
| Identity provider | Keycloak Operator |

OpenEBS chart가 snapshot-controller와 csi-snapshotter를 함께 배포한다. 별도 external-snapshotter controller를 설치하지 않는다.

`keycloak` Application은 Keycloak Operator와 Keycloak CR을 관리한다. 외부 Keycloak을 가리키는 route는 CPA Keycloak route로 교체한다.

### 통신 보안

외부 요청은 Istio gateway에서 HTTPS로 수신한다. Gateway는 Vault service의 HTTP listener로 요청을 전달하고 Vault는 `tlsDisable: true`를 사용한다. 이 설정은 MESH 적용 시점과 독립적이다.

Cilium policy는 접근 가능한 source와 port를 제한한다. Istio는 MESH 단계에서 workload identity 기반 STRICT mTLS와 AuthorizationPolicy를 적용한다. MESH 적용 전 gateway와 Vault service 사이의 요청은 평문이다. Vault Raft cluster 통신은 Vault가 관리하는 mTLS를 사용한다.

JWT는 bearer JWT를 보내는 요청에만 요구한다. Vault token과 Kubernetes auth를 사용하는 내부 client에는 JWT를 요구하지 않는다.

### Backup 구조

OpenEBS volume snapshot backup은 현재 K3s와 OpenEBS runtime의 crash-consistent 복구 지점이다. Vault Raft, PostgreSQL Barman과 database dump는 새 런타임에도 복원하는 application data backup이다.

```text
OpenEBS thin PVC
  → VolumeSnapshot
  → Velero CSI Snapshot Data Movement
  → Kopia repository
  → s3://ghilbut-backups/snapshots/k3s/cpa/volumes/

Vault Integrated Raft
  → vault operator raft snapshot save
  → s3://ghilbut-backups/data/vault/raft/

CloudNativePG
  ├─ Barman base backup와 WAL → s3://ghilbut-backups/data/postgresql/barman/
  └─ pg_dump custom format   → s3://ghilbut-backups/data/postgresql/dump/
```

Velero data mover는 OpenEBS snapshot에서 임시 thin volume을 만들고 S3 repository로 data를 이동한다. 복원할 때 `DataDownload`가 새 thin PVC를 만들고 repository data를 기록한다.

`ghilbut-backups`는 public 접근을 차단하고 TLS와 기본 SSE-S3 암호화를 적용한다. Backup job은 자신의 prefix만 변경한다.

| Principal | 변경 가능 prefix |
| --- | --- |
| Velero ServiceAccount | `snapshots/k3s/cpa/volumes/` |
| Vault backup ServiceAccount | `data/vault/raft/` |
| PostgreSQL backup ServiceAccount | `data/postgresql/barman/`, `data/postgresql/dump/` |

Backup은 UTC 기준으로 서로 겹치지 않게 실행한다.

| Backup | 주기 | 보존 수 | 최대 보존 기간 | 복구 성격 |
| --- | --- | --- | --- | --- |
| Vault OpenEBS snapshot | `10 */6 * * *` | 28 | 7일 | crash-consistent |
| Vault Raft data backup | `0 */6 * * *` | 28 | 7일 | application-consistent |
| PostgreSQL OpenEBS snapshot | `50 */6 * * *` | 28 | 7일 | crash-consistent |
| PostgreSQL logical data backup | `30 */6 * * *` | 28 | 7일 | application-consistent |
| PostgreSQL Barman base backup | `0 0 2 * * *` | 기간 기준 | 7일 | application-consistent |
| PostgreSQL WAL archive | 연속 | Barman backup과 함께 만료 | 7일 | point-in-time recovery |

Velero Schedule은 5-field cron을 사용한다. CloudNativePG ScheduledBackup은 seconds를 포함한 6-field cron을 사용한다. Velero Schedule은 TTL `168h`를 사용하고 완료된 backup을 28개까지만 유지한다. Kopia repository maintenance는 삭제한 backup의 orphan data를 정리한다. Vault와 PostgreSQL backup job도 28개를 초과한 object를 삭제한다.

### Credential 경계

- Vault KMS key와 application data backup prefix는 플랫폼 공통 자산이다.
- 현재 런타임의 ServiceAccount만 해당 런타임용 IAM role을 수임한다.
- Vault server, Velero와 application backup job은 static AWS access key를 사용하지 않는다.
- Velero Kopia repository password는 Vault 없이 복구할 수 있어야 한다.
- Vault recovery key는 SecurityTooling AWS Secrets Manager에 KMS 암호화하여 저장한다.
- Initial root token은 초기 설정을 마친 뒤 revoke하고 저장하지 않는다.
- Vault Secrets Operator는 Application별 Kubernetes auth role을 사용한다.
- Keycloak Operator는 Vault Secrets Operator가 만든 PostgreSQL Secret을 참조한다.
- OIDC 장애 복구는 K3s administrator certificate와 Argo CD port-forward를 사용한다.

### 복구 순서

1. [[k3s/runbooks/CPA-RESTORE|K3s snapshot 복원]]을 먼저 실행한다.
2. K3s snapshot 복원이 실패하면 K3s와 [[runbooks/BOOTSTRAP|Bootstrap]]부터 Current runbook까지 다시 실행한다.
3. Velero와 Kopia repository password를 준비한다.
4. Vault OpenEBS volume snapshot backup을 복원한다. 실패하면 새 Vault와 같은 KMS key를 준비하고 Raft data backup을 복원한다.
5. Vault policy, Kubernetes auth와 대표 secret을 확인한다.
6. PostgreSQL OpenEBS volume snapshot backup을 복원한다. 실패하면 Barman point-in-time recovery를 실행하고, Barman 복원도 실패하면 logical data backup을 새 cluster에 복원한다.
7. Vault database credential을 PostgreSQL에 다시 연결한다.
8. Keycloak, Vault OIDC, K3s OIDC와 Argo CD OIDC를 순서대로 확인한다.
9. Cilium policy와 Istio authorization을 적용한다.
10. 복구에 사용한 Application source revision을 `main`으로 되돌린다.

OpenEBS와 Velero의 backup·restore 동작은 다음 명령으로 검증한다.

```shell
kubectl --context cpa api-resources \
  --api-group=snapshot.storage.k8s.io
kubectl --context cpa get storageclass \
  openebs-lvm-thin \
  -o custom-columns=NAME:.metadata.name,PROVISIONER:.provisioner,THIN:.parameters.thinProvision,VG:.parameters.volgroup
kubectl --context cpa get volumesnapshotclass \
  openebs-lvm-snapshot \
  -o custom-columns=NAME:.metadata.name,DRIVER:.driver,POLICY:.deletionPolicy

export BACKUP_NAME='<BACKUP_NAME>'
export BACKUP_NAMESPACE='<NAMESPACE>'
velero --kubecontext cpa backup create "$BACKUP_NAME" \
  --include-namespaces "$BACKUP_NAMESPACE" \
  --snapshot-move-data \
  --ttl 168h
kubectl --context cpa -n velero get datauploads \
  -l "velero.io/backup-name=$BACKUP_NAME" \
  -o wide
velero --kubecontext cpa backup describe "$BACKUP_NAME"
unset BACKUP_NAME BACKUP_NAMESPACE
```

복원 검증은 운영 namespace와 다른 임시 namespace에서 실행한다.

```shell
export BACKUP_NAME='<BACKUP_NAME>'
export RESTORE_NAME='<RESTORE_NAME>'
export SOURCE_NAMESPACE='<SOURCE_NAMESPACE>'
export RESTORE_NAMESPACE='<RESTORE_NAMESPACE>'
velero --kubecontext cpa restore create "$RESTORE_NAME" \
  --from-backup "$BACKUP_NAME" \
  --namespace-mappings "$SOURCE_NAMESPACE:$RESTORE_NAMESPACE"
kubectl --context cpa -n velero get datadownloads \
  -l "velero.io/restore-name=$RESTORE_NAME" \
  -o wide
velero --kubecontext cpa restore describe "$RESTORE_NAME"
kubectl --context cpa -n "$RESTORE_NAMESPACE" get pvc,pod
unset BACKUP_NAME RESTORE_NAME SOURCE_NAMESPACE RESTORE_NAMESPACE
```

Vault Raft data backup은 다음 명령으로 생성하고 S3에 저장한다. 복구할 때 같은 object를 내려받아 검사한 뒤 복원한다.

```shell
export VAULT_SNAPSHOT='<SNAPSHOT_FILE>'
export VAULT_S3_KEY="data/vault/raft/$VAULT_SNAPSHOT"
vault operator raft snapshot save "$VAULT_SNAPSHOT"
vault operator raft snapshot inspect "$VAULT_SNAPSHOT"
aws s3 cp "$VAULT_SNAPSHOT" "s3://ghilbut-backups/$VAULT_S3_KEY" \
  --checksum-algorithm SHA256

aws s3 cp "s3://ghilbut-backups/$VAULT_S3_KEY" "$VAULT_SNAPSHOT"
vault operator raft snapshot inspect "$VAULT_SNAPSHOT"
vault operator raft snapshot restore -force "$VAULT_SNAPSHOT"
unset VAULT_SNAPSHOT VAULT_S3_KEY
```

PostgreSQL logical data backup은 custom format으로 생성하고 S3에 저장한다. 복구 검증은 새 database를 만들고 같은 object를 복원하여 수행한다.

```shell
export PGDATABASE='<SOURCE_DATABASE>'
export PG_DUMP_FILE="${PGDATABASE}-$(date -u +%Y%m%dT%H%M%SZ).dump"
export PG_S3_KEY="data/postgresql/dump/$PG_DUMP_FILE"
pg_dump \
  --format=custom \
  --no-owner \
  --no-privileges \
  --file="$PG_DUMP_FILE"
aws s3 cp "$PG_DUMP_FILE" "s3://ghilbut-backups/$PG_S3_KEY" \
  --checksum-algorithm SHA256

export PG_RESTORE_DATABASE='<RESTORE_DATABASE>'
createdb "$PG_RESTORE_DATABASE"
aws s3 cp "s3://ghilbut-backups/$PG_S3_KEY" "$PG_DUMP_FILE"
pg_restore \
  --exit-on-error \
  --no-owner \
  --no-privileges \
  --dbname="$PG_RESTORE_DATABASE" \
  "$PG_DUMP_FILE"
unset PGDATABASE PG_DUMP_FILE PG_S3_KEY PG_RESTORE_DATABASE
```

Backup을 삭제하거나 운영 data를 덮어쓰기 전에 대상 이름, namespace, S3 key와 checksum을 다시 확인한다.

### OpenTofu와 Git revision

- 정상 Plan과 Apply는 root 전체를 사용한다.
- `-target`은 복구 runbook이 resource address와 종료 조건을 지정한 경우에만 사용한다.
- Targeted Apply 뒤에는 target 없는 전체 Plan을 실행하여 변경 사항이 없어야 한다.
- 모든 Application의 정상 revision은 `main`이다.
- Archive SHA는 복구 중인 Application에만 임시 적용하고 복구가 끝나면 `main`으로 되돌린다.

## Pod Security Standards

![[knowledge/rulebooks/k8s/SECURITY#Pod Security Standards]]
