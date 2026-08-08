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

이 절은 `SECURITY` 실행 단계가 공유하는 제품, storage, backup, credential과 복구 기준을 정의한다. 실제 설치와 복구 절차는 [[runbooks/SECURITY|Security]]를 따른다.

### 실행 환경

CPA는 단일 K3s server와 단일 OpenEBS LVM volume group을 사용한다. Vault, PostgreSQL과 Keycloak은 각각 replica 한 개로 시작한다. 이 구성은 node 장애를 견디는 고가용성을 제공하지 않는다. K3s snapshot과 S3 application backup이 node 장애 복구를 담당한다.

K3s host는 `dm_snapshot`과 `dm_thin_pool` kernel module을 부팅할 때 로드한다. [[k3s/RUNBOOK#1. host 준비|K3s host 준비]]에서 두 module과 device mapper target을 확인한 뒤 OpenEBS thin volume을 사용한다.

기존 `openebs-lvm` StorageClass는 thick volume을 만든다. OpenEBS LocalPV LVM은 thick volume의 snapshot을 만들 수 있지만 [snapshot에서 volume을 복원하는 기능](https://openebs.io/docs/main/user-guides/local-storage-user-guide/local-pv-lvm/advanced-operations/lvm-volume-restore)은 thin volume만 지원한다. `SECURITY`의 stateful Application은 다음 `openebs-lvm-thin` StorageClass와 `openebs-lvm-snapshot` VolumeSnapshotClass를 사용한다.

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: openebs-lvm-thin
provisioner: local.csi.openebs.io
allowVolumeExpansion: true
parameters:
  storage: lvm
  volgroup: openebs
  thinProvision: "yes"
reclaimPolicy: Retain
volumeBindingMode: WaitForFirstConsumer
---
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshotClass
metadata:
  name: openebs-lvm-snapshot
driver: local.csi.openebs.io
deletionPolicy: Delete
```

`Retain`은 Application 삭제가 PVC와 data volume 삭제로 이어지는 것을 막는다. SnapshotClass의 `Delete`는 Velero가 S3 data movement를 마친 뒤 임시 OpenEBS snapshot을 정리하게 한다.

### 제품과 version

다음 version은 2026-08-08 기준 구현 version이다. Application은 Helm chart version, Kustomize tag와 container image tag를 함께 고정한다. Version 변경은 별도 Issue와 PR에서 backup과 restore를 다시 검증한다.

| 책임 | 제품 | 고정 version |
| --- | --- | --- |
| Local volume | [OpenEBS LVM LocalPV](https://openebs.io/docs/main/user-guides/local-storage-user-guide/local-pv-lvm/lvm-overview) | Helm `1.9.1` |
| Snapshot API | [Kubernetes external-snapshotter](https://github.com/kubernetes-csi/external-snapshotter) | OpenEBS chart bundle `v7.0.0` |
| Snapshot S3 data movement | [Velero CSI Snapshot Data Movement](https://velero.io/docs/main/csi-snapshot-data-movement/) | Helm `12.1.0`, image `1.18.2` |
| Velero S3 client | [Velero plugin for AWS](https://github.com/velero-io/velero-plugin-for-aws) | `v1.14.2` |
| Secret store | [Vault Helm](https://developer.hashicorp.com/vault/docs/deploy/kubernetes/helm) | Helm `0.34.0`, Vault `2.0.3` |
| Secret delivery | [Vault Secrets Operator](https://developer.hashicorp.com/vault/docs/deploy/kubernetes/vso) | Helm `1.5.0` |
| PostgreSQL operator | [CloudNativePG](https://cloudnative-pg.io/docs/1.30/) | Helm `0.29.0`, operator `1.30.0` |
| PostgreSQL | [PostgreSQL](https://www.postgresql.org/docs/18/) | `18.4` |
| PostgreSQL physical backup | [Barman Cloud Plugin](https://cloudnative-pg.io/plugin-barman-cloud/) | `0.7.1` |
| Identity provider | [Keycloak Operator](https://www.keycloak.org/operator/installation) | Kustomize와 Keycloak `26.7.1` |

CloudNativePG와 Vault는 단일 replica로 시작한다. Replica 수를 늘리려면 K3s server와 OpenEBS volume이 서로 다른 node에 있어야 한다.

OpenEBS chart가 snapshot-controller와 csi-snapshotter를 함께 배포한다. 별도 external-snapshotter controller를 설치하지 않는다.

`keycloak` Application은 CPA의 Keycloak Operator와 Keycloak CR을 관리한다. 외부 Keycloak을 가리키는 ServiceEntry, DestinationRule과 VirtualService는 CPA Keycloak route로 교체한다.

### Backup 구조

OpenEBS snapshot은 volume의 crash-consistent 복구 지점이다. Privileged `fsfreeze` hook은 사용하지 않는다. Vault Raft snapshot, PostgreSQL Barman backup과 database dump가 application-consistent 복구 지점을 제공한다.

```text
OpenEBS thin PVC
  → VolumeSnapshot
  → Velero CSI Snapshot Data Movement
  → Kopia repository
  → s3://ghilbut-backups/velero/cpa/

Vault integrated Raft
  → vault operator raft snapshot save
  → s3://ghilbut-backups/vault/cpa/raft/

CloudNativePG
  ├─ Barman base backup와 WAL → s3://ghilbut-backups/postgresql/cpa/barman/
  └─ pg_dump custom format   → s3://ghilbut-backups/postgresql/cpa/dump/
```

Velero는 built-in Kopia data mover를 사용한다. Data mover는 OpenEBS snapshot에서 임시 thin volume을 만들고 S3 repository로 data를 이동한다. 복원할 때 `DataDownload`가 새 thin PVC를 만들고 repository data를 기록한다.

`ghilbut-backups`는 TLS와 기본 SSE-S3 암호화를 적용하고 versioning을 `Suspended`로 유지한다. Backup job은 다음 prefix만 변경할 수 있다.

| Principal | 변경 가능 prefix |
| --- | --- |
| Velero ServiceAccount | `velero/cpa/` |
| Vault backup ServiceAccount | `vault/cpa/raft/` |
| PostgreSQL backup ServiceAccount | `postgresql/cpa/barman/`, `postgresql/cpa/dump/` |

Backup은 UTC 기준으로 서로 겹치지 않게 실행한다.

| Backup | 주기 | 보존 수 | 최대 보존 기간 | 복구 성격 |
| --- | --- | --- | --- | --- |
| Vault OpenEBS snapshot | `10 */6 * * *` | 28 | 7일 | crash-consistent |
| Vault Raft snapshot | `0 */6 * * *` | 28 | 7일 | application-consistent |
| PostgreSQL OpenEBS snapshot | `50 */6 * * *` | 28 | 7일 | crash-consistent |
| PostgreSQL logical dump | `30 */6 * * *` | 28 | 7일 | application-consistent |
| PostgreSQL Barman base backup | `0 0 2 * * *` | 기간 기준 | 7일 | application-consistent |
| PostgreSQL WAL archive | 연속 | Barman backup과 함께 만료 | 7일 | point-in-time recovery |

Velero Schedule은 5-field cron을 사용한다. CloudNativePG ScheduledBackup은 seconds를 포함한 6-field cron을 사용한다. Velero Schedule은 TTL `168h`를 사용하고 완료된 backup을 28개까지만 유지한다. Kopia repository maintenance가 삭제한 backup의 orphan data를 정리해야 backup 삭제가 완료된다. Vault와 PostgreSQL backup job도 28개를 초과한 object를 삭제한다.

### Credential 경계

- Vault server는 CPA ServiceAccount token으로 SecurityTooling의 AWS KMS role을 수임한다. Static AWS access key를 사용하지 않는다.
- Velero와 backup job은 workload별 CPA ServiceAccount token으로 SharedServices S3 writer role을 수임한다.
- Velero Kopia repository password는 Vault 복원 전에 필요하다. `apps/tofu`가 password를 만들고 `apps.tfstate`와 write-only Kubernetes Secret으로 관리한다.
- Vault recovery key는 SecurityTooling AWS Secrets Manager에 KMS 암호화하여 저장한다. Initial root token은 초기 설정을 마친 뒤 revoke하고 저장하지 않는다.
- Vault Secrets Operator는 Application별 Kubernetes auth role을 사용한다. Destination Secret은 해당 Application ServiceAccount만 읽는다.
- Keycloak Operator는 PostgreSQL username과 password를 Kubernetes Secret reference로 읽는다. Vault Secrets Operator가 이 Secret을 만들고 rotation 때 Keycloak을 rolling restart한다.
- Keycloak 장애에서는 K3s administrator certificate, Vault recovery key와 Argo CD port-forward 절차를 사용한다. OIDC를 비상 복구의 선행 조건으로 사용하지 않는다.

### 복구 순서

CPA 복구는 다음 순서를 사용한다.

1. [[k3s/runbooks/CPA-RESTORE|K3s snapshot 복원]]을 먼저 실행한다.
2. K3s snapshot 복원이 실패하면 [[runbooks/BOOTSTRAP|Bootstrap]]부터 Current runbook까지 실행한다.
3. Velero와 Kopia repository password를 준비한다.
4. Vault OpenEBS snapshot을 복원한다. 실패하면 새 Vault와 동일한 AWS KMS seal을 준비하고 Raft snapshot을 `-force`로 복원한다.
5. Vault policy, Kubernetes auth와 대표 secret을 확인한다.
6. PostgreSQL OpenEBS snapshot을 복원한다. 실패하면 Barman point-in-time recovery를 실행하고, Barman 복원도 실패하면 logical dump를 새 cluster에 복원한다.
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

Vault Raft snapshot은 다음 명령으로 생성하고 S3에 저장한다. 복구할 때 같은 object를 내려받아 검사한 뒤 복원한다.

```shell
export VAULT_SNAPSHOT='<SNAPSHOT_FILE>'
export VAULT_S3_KEY="vault/cpa/raft/$VAULT_SNAPSHOT"
vault operator raft snapshot save "$VAULT_SNAPSHOT"
vault operator raft snapshot inspect "$VAULT_SNAPSHOT"
aws s3 cp "$VAULT_SNAPSHOT" "s3://ghilbut-backups/$VAULT_S3_KEY" \
  --checksum-algorithm SHA256

aws s3 cp "s3://ghilbut-backups/$VAULT_S3_KEY" "$VAULT_SNAPSHOT"
vault operator raft snapshot inspect "$VAULT_SNAPSHOT"
vault operator raft snapshot restore -force "$VAULT_SNAPSHOT"
unset VAULT_SNAPSHOT VAULT_S3_KEY
```

PostgreSQL logical backup은 custom format으로 생성하고 S3에 저장한다. 복구 검증은 새 database를 만들고 같은 object를 복원하여 수행한다.

```shell
export PGDATABASE='<SOURCE_DATABASE>'
export PG_DUMP_FILE="${PGDATABASE}-$(date -u +%Y%m%dT%H%M%SZ).dump"
export PG_S3_KEY="postgresql/cpa/dump/$PG_DUMP_FILE"
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

실제 실행 runbook은 backup을 삭제하거나 운영 data를 덮어쓰기 전에 대상 이름, namespace, S3 key와 checksum을 다시 확인한다.

### OpenTofu와 Git revision

- 정상 Plan과 Apply는 root 전체를 사용한다.
- `-target`은 복구 runbook이 resource address와 종료 조건을 지정한 경우에만 사용한다.
- Targeted Apply 뒤에는 target 없는 전체 Plan을 실행하여 변경 사항이 없어야 한다.
- 모든 Application의 정상 revision은 `main`이다.
- Archive SHA는 복구 중인 Application에만 임시 적용하고 복구가 끝나면 `main`으로 되돌린다.

## Pod Security Standards

![[knowledge/rulebooks/k8s/SECURITY#Pod Security Standards]]
