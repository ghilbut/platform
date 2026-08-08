---
type: run
area: apps
cluster: cpa
---

# Security

CPA에 Vault, PostgreSQL과 Keycloak을 설치하고 workload 접근, backup, restore와 운영자 인증을 구성한다. 제품과 복구 설계는 [[apps/RUNBOOK#SECURITY 설계|SECURITY 설계]]를 따른다.

## A. 시작 조건

`BOOTSTRAP`은 다음 GitOps 원본으로 완료되어 있어야 한다.

| 항목 | 값 |
| --- | --- |
| tag | `bootstrap-v1` |
| Archive SHA | `d14b63a3e59f076afcd1b5e15f2e31ae81800f33` |

```shell
export BOOTSTRAP_TAG='bootstrap-v1'
export BOOTSTRAP_REVISION='d14b63a3e59f076afcd1b5e15f2e31ae81800f33'

git fetch origin main "refs/tags/${BOOTSTRAP_TAG}:refs/tags/${BOOTSTRAP_TAG}"
test "$(git rev-list -n 1 "$BOOTSTRAP_TAG")" = "$BOOTSTRAP_REVISION"
git merge-base --is-ancestor "$BOOTSTRAP_REVISION" origin/main

kubectl --context cpa cluster-info
kubectl --context cpa wait \
  --for=condition=Ready \
  node/cpa \
  --timeout=10m

ssh cpa 'lsmod | grep -E "^dm_(snapshot|thin_pool) "'
ssh cpa 'sudo dmsetup targets | grep -E "^(snapshot|thin)"'
kubectl --context cpa wait \
  --for=condition=Established \
  --timeout=10m \
  crd/volumesnapshotclasses.snapshot.storage.k8s.io \
  crd/volumesnapshotcontents.snapshot.storage.k8s.io \
  crd/volumesnapshots.snapshot.storage.k8s.io
kubectl --context cpa -n ebs wait \
  --for=condition=Available \
  deployment/ebs-lvm-localpv-controller \
  --timeout=10m

kubectl --context cpa -n argo get applications -o json \
  | jq -e --arg repository 'https://github.com/ghilbut/platform.git' '
      [
        .items[].spec
        | (([.source] + (.sources // []))[]?)
        | select(.repoURL == $repository)
        | .targetRevision
      ] as $revisions
      | ($revisions | length > 0)
        and all($revisions[]; . == "main")
    '

AWS_PROFILE=ghilbut-backup-recovery \
  aws s3api head-bucket \
    --bucket ghilbut-backups

unset BOOTSTRAP_TAG BOOTSTRAP_REVISION
```

## B. 실행 순서

각 Issue는 blocker가 닫힌 뒤 실행한다. 하나의 Issue에는 하나의 PR을 연결하고 적용 뒤 전체 상태를 확인한다.

| 순서 | 범위 | 실행 Issue | 완료 결과 |
| --- | --- | --- | --- |
| 1 | Vault | #225 → #226 → #227 → #228 → #229 | auto-unseal, 접근 정책, S3 backup과 restore |
| 2 | PostgreSQL | #230 → (#231, #232) → #233 | database, Vault credential, S3 backup과 restore |
| 3 | Keycloak과 운영자 인증 | #234 → #235 → #236 → #237 → (#238, #239) | Keycloak, Vault·K3s·Argo CD OIDC와 비상 접근 |
| 4 | Workload 보안 | #240 → #241 → #242 → #243 | Pod 보안, Cilium policy, Istio mTLS와 authorization |
| 5 | 통합 복구 | #244 → #245 | 전체 재설치·데이터 복구와 인증 장애 복구 |
| 6 | 완료 | #246 | `SECURITY` Archive와 다음 Current runbook 전환 |

#231과 #232는 #230 완료 뒤 함께 진행할 수 있다. #238과 #239는 #237 완료 뒤 함께 진행할 수 있다. 실제 명령과 검증 결과는 해당 Issue의 PR에서 이 문서에 추가한다.

## C. 복구 진입점

CPA 복구는 다음 순서를 사용한다.

1. [[k3s/runbooks/CPA-RESTORE|K3s snapshot 복원]]을 실행한다.
2. K3s snapshot 복원이 실패하면 [[k3s/runbooks/CPA|CPA K3s 기반 준비]]와 [[apps/runbooks/BOOTSTRAP|Bootstrap]]을 실행한다.
3. `BOOTSTRAP` 완료 뒤 모든 Application의 platform Git source revision을 `main`으로 되돌린다.
4. 이 문서의 시작 조건을 확인하고 완료되지 않은 첫 번째 SECURITY Issue부터 실행한다.
5. 데이터는 Vault → PostgreSQL → Keycloak → 인증 연동 → workload 보안 순서로 복원한다.

Archived Application을 복구할 때만 해당 Application의 platform Git source revision을 Archive SHA로 임시 override한다. 복구 단계가 끝나면 즉시 `main`으로 되돌린다.

## D. 완료 조건

- Vault, PostgreSQL과 Keycloak이 Ready다.
- Vault OpenEBS·Raft snapshot과 PostgreSQL OpenEBS·Barman·logical backup이 S3에 저장되고 실제 restore가 성공한다.
- Vault, K3s와 Argo CD의 Keycloak OIDC 로그인과 비상 접근이 성공한다.
- Cilium policy와 Istio authorization 적용 뒤 정상 workload, backup과 복구 흐름이 유지된다.
- `BOOTSTRAP`부터 `SECURITY`까지 전체 재설치와 데이터 복구가 성공한다.
- 모든 Application의 platform Git source revision이 `main`이다.
- 사용자가 `SECURITY` Archive와 다음 단계 진행을 명시적으로 지시한다.
