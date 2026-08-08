---
type: run
area: k3s
cluster: cpa
operation: restore
---

# CPA K3s snapshot 복원

CPA embedded etcd snapshot을 첫 번째 복구 절차로 실행한다. 이 절차는 Kubernetes API state를
snapshot 생성 시점으로 되돌린다.

> [!danger] 복원 범위
> Snapshot에는 Kubernetes Secret과 K3s CA private key가 포함된다. 신뢰하는
> `ghilbut-backups/k3s/cpa/` object만 사용한다. PersistentVolume과 애플리케이션 데이터는 별도
> S3 백업에서 복원한다.

## A. 시작 조건

다음 조건을 모두 충족한 뒤 복원을 시작한다.

- `ghilbut-backup-recovery` AWS profile을 [[aws/RUNBOOK#Source profiles|AWS operations]]에 따라 준비했다.
- `k3s.tfstate`의 `cpa_server_token` output을 읽을 수 있다.
- 복원 대상 CPA에 [[CPA#C. K3s server|CPA K3s server]]와 동일한 server 설정이 있다.
- 복원 중인 CPA에서 Applications bootstrap과 애플리케이션 데이터 복원을 실행하지 않는다.

## B. Snapshot 선택과 다운로드

관리자 컴퓨터에서 현재 S3 object를 최신 수정 시각순으로 확인한다. `.metadata/` object는 선택하지
않는다.

```shell
# administrator computer
export AWS_SDK_LOAD_CONFIG=1
export AWS_PROFILE='ghilbut-backup-recovery'

aws sso login --sso-session ghilbut
aws sts get-caller-identity \
  --query '{Account:Account,Arn:Arn}' \
  --output table
aws s3api list-objects-v2 \
  --bucket ghilbut-backups \
  --prefix k3s/cpa/ \
  --query 'reverse(sort_by(Contents[?starts_with(Key, `k3s/cpa/.metadata/`) == `false`], &LastModified))[].{Modified:LastModified,Size:Size,Key:Key}' \
  --output table
```

Versioning 중단 전에 current object에서 삭제된 snapshot은 수명 주기 만료 전까지 S3 noncurrent
version에서 찾는다.

```shell
# administrator computer
aws s3api list-object-versions \
  --bucket ghilbut-backups \
  --prefix k3s/cpa/ \
  --query 'reverse(sort_by(Versions[?IsLatest == `false` && starts_with(Key, `k3s/cpa/.metadata/`) == `false`], &LastModified))[].{Modified:LastModified,Size:Size,Key:Key,VersionId:VersionId}' \
  --output table
```

선택한 object key와 version ID를 지정한다. Current object는 `SNAPSHOT_VERSION_ID`를 빈 값으로
둔다. Snapshot object는 `k3s/cpa/` 바로 아래에 있으며 파일 이름에는 영문자, 숫자, `.`, `_`,
`-`만 사용한다.

```shell
# administrator computer
export SNAPSHOT_KEY='<k3s/cpa/SNAPSHOT>'
export SNAPSHOT_VERSION_ID=''
export SNAPSHOT_NAME="${SNAPSHOT_KEY#k3s/cpa/}"

case "$SNAPSHOT_KEY" in
  k3s/cpa/.metadata/*|k3s/cpa/) \
    printf 'Invalid snapshot key: %s\n' "$SNAPSHOT_KEY" >&2; exit 1 ;;
  k3s/cpa/*) ;;
  *) printf 'Invalid snapshot key: %s\n' "$SNAPSHOT_KEY" >&2; exit 1 ;;
esac
case "$SNAPSHOT_NAME" in
  ''|*/*|*[!A-Za-z0-9._-]*) \
    printf 'Invalid snapshot name: %s\n' "$SNAPSHOT_NAME" >&2; exit 1 ;;
esac

export SNAPSHOT_DOWNLOAD_DIR="$(mktemp -d)"

if [ -n "$SNAPSHOT_VERSION_ID" ]; then
  aws s3api get-object \
    --bucket ghilbut-backups \
    --key "$SNAPSHOT_KEY" \
    --version-id "$SNAPSHOT_VERSION_ID" \
    "$SNAPSHOT_DOWNLOAD_DIR/$SNAPSHOT_NAME"
else
  aws s3api get-object \
    --bucket ghilbut-backups \
    --key "$SNAPSHOT_KEY" \
    "$SNAPSHOT_DOWNLOAD_DIR/$SNAPSHOT_NAME"
fi

test -s "$SNAPSHOT_DOWNLOAD_DIR/$SNAPSHOT_NAME"
```

## C. Snapshot 전송

선택한 snapshot을 CPA의 K3s snapshot directory에 mode `600`으로 저장한다.

```shell
# administrator computer
if ! ssh cpa \
  "sudo install -D -m 600 /dev/stdin '/var/lib/rancher/k3s/server/db/snapshots/$SNAPSHOT_NAME'" \
  < "$SNAPSHOT_DOWNLOAD_DIR/$SNAPSHOT_NAME"; then
  exit 1
fi
rm -- "$SNAPSHOT_DOWNLOAD_DIR/$SNAPSHOT_NAME"
rmdir "$SNAPSHOT_DOWNLOAD_DIR"
unset SNAPSHOT_DOWNLOAD_DIR
```

## D. 단일 server 복원

관리자 컴퓨터에서 state의 server token을 CPA K3s configuration file에 다시 저장한다. Token은
화면에 출력하지 않는다.

```shell
# administrator computer
export AWS_SDK_LOAD_CONFIG=1
export AWS_PROFILE='ghilbut-tofu-plan-for-workloads'

tofu -chdir=k3s/tofu init -reconfigure
CPA_SERVER_TOKEN="$(tofu -chdir=k3s/tofu output -raw cpa_server_token)"
test -n "$CPA_SERVER_TOKEN"

{
  printf 'token: "'
  printf '%s' "$CPA_SERVER_TOKEN"
  printf '"\n'
} | ssh cpa \
  'sudo install -D -m 600 /dev/stdin /etc/rancher/k3s/config.yaml.d/10-server-token.yaml'

unset CPA_SERVER_TOKEN
```

K3s S3 설정이 server config에 있으므로 로컬 파일 복원에는 `--etcd-s3=false`를 지정한다.

```shell
# cpa
export SNAPSHOT_NAME='<SNAPSHOT_NAME>'
export SNAPSHOT_PATH="/var/lib/rancher/k3s/server/db/snapshots/$SNAPSHOT_NAME"

test -s "$SNAPSHOT_PATH"
sudo test -s /etc/rancher/k3s/config.yaml.d/10-server-token.yaml
sudo systemctl stop k3s

if ! sudo k3s server \
  --cluster-reset \
  --cluster-reset-restore-path="$SNAPSHOT_PATH" \
  --etcd-s3=false; then
  printf 'CPA snapshot restore failed.\n' >&2
  exit 1
fi

sudo systemctl start k3s
sudo systemctl is-active k3s
```

복원 명령은 `Managed etcd cluster membership has been reset` 메시지를 출력해야 한다. K3s를 정상
시작하면 `/var/lib/rancher/k3s/server/db/reset-flag`가 제거된다.

## E. 복원 확인

관리자 컴퓨터에서 control plane, Cilium, Argo CD와 Application object를 순서대로 확인한다.

```shell
# administrator computer
timeout 10m sh -c \
  'until kubectl --context cpa get --raw="/readyz" >/dev/null 2>&1; do sleep 5; done'
kubectl --context cpa get --raw='/readyz?verbose'
kubectl --context cpa wait --for=condition=Ready node/cpa --timeout=10m
kubectl --context cpa -n kube-system rollout status daemonset/cilium --timeout=10m
kubectl --context cpa -n kube-system rollout status deployment/cilium-operator --timeout=10m
kubectl --context cpa -n argo wait \
  --for=condition=Available deployment/cd-server \
  --timeout=10m
kubectl --context cpa -n argo get applications \
  -o custom-columns=NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status
kubectl --context cpa -n argo get applications -o name \
  | grep -q '^application.argoproj.io/'
```

위 명령이 모두 성공하면 `k3s/tofu`를 다음과 같이 적용하여 snapshot에 포함된 S3 configuration
Secret을 현재 state의 access key로 교체한다.

```shell
# administrator computer
export AWS_SDK_LOAD_CONFIG=1
export AWS_PROFILE='ghilbut-tofu-apply-for-workloads'

tofu -chdir=k3s/tofu init -reconfigure \
  -backend-config=tofu-state-apply.tfbackend
tofu -chdir=k3s/tofu apply \
  -replace=kubernetes_secret_v1.cpa_snapshot_s3
```

[[CPA#G. Snapshot 확인|CPA snapshot 확인]]을 완료한 뒤 각 애플리케이션을 준비하고 애플리케이션
데이터를 별도 S3 백업에서 복원한다.

## F. 복원 실패

다음 중 하나가 발생하면 snapshot 복원은 실패다.

- K3s가 snapshot checksum 또는 server token 검증에 실패한다.
- `k3s server --cluster-reset` 명령이 실패한다.
- K3s를 시작한 뒤 10분 안에 `/readyz`가 성공하지 않는다.
- CPA node, Cilium, Argo CD 또는 Application object를 복구하지 못한다.

실패한 상태에서 cluster reset을 반복하거나 Applications `BOOTSTRAP`을 실행하지 않는다.
[[CPA#C. K3s server|CPA K3s server]]부터 다시 실행하여 실패한 K3s 상태를 제거한다. K3s 기반을
완료한 뒤 [[apps/RUNBOOK#실행 문서|Applications 실행 문서]]를 `BOOTSTRAP`부터 실행한다.
