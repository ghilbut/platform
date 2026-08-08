---
type: run
area: k3s
cluster: cpa
---

# CPA K3s 기반 준비

CPA는 단일 control-plane K3s 클러스터다. 인증 정보와 token은 문서, Git과 명령 출력에 기록하지
않는다. Snapshot access key와 server token은 `k3s.tfstate`에서 관리한다.

> [!info] 공통 절차
> ![[k3s/RUNBOOK#B. 설치 값]]

## A. 적용 값

| 항목 | 값 |
| --- | --- |
| cluster, context, node | `cpa` |
| control-plane IP | `192.168.254.4` |
| Service CIDR | `172.31.128.0/17` |
| CoreDNS Service IP | `172.31.128.10` |
| Cilium Pod CIDR | `172.31.0.0/17` |
| ServiceAccount issuer | `https://oidc.k3s.ghilbut.com/cpa` |
| K3s | `v1.36.2+k3s1` |
| Cilium chart | `1.20.0` |
| Argo CD chart | `9.5.13` |
| OpenEBS LVM device | `/dev/sda10` |
| OpenEBS LVM volume group | `openebs` |
| etcd snapshot schedule | `0 */6 * * *` |
| local snapshot retention | `8` |
| S3 bucket | `ghilbut-backups` |
| S3 folder | `k3s/cpa` |
| S3 snapshot retention | `28` |
| S3 Versioning | `Suspended` |
| 기존 S3 noncurrent version retention | 90일 |

## B. host와 OpenEBS LVM

VM은 Synology Virtual Machine Manager에서 `cpa`로 실행한다. VM은 4 vCPU, 메모리 12GiB, 1TiB disk, Default VM Network의 `192.168.254.4` 고정 주소를 사용한다.

| 파티션 또는 경로 | 용량 | 용도 |
| --- | ---: | --- |
| `/dev/sda2` | 4GiB | `/boot` |
| `/dev/sda3` | 128GiB | `/` |
| `/dev/sda4` | 8GiB | `/home` |
| `/dev/sda5` | 32GiB | `/var/log` |
| `/dev/sda6` | 128GiB | `/var/lib/kubelet` |
| `/dev/sda7` | 8GiB | `/var/lib/rancher` |
| `/dev/sda8` | 64GiB | `/var/lib/rancher/k3s/server/db` |
| `/dev/sda9` | 256GiB | `/var/lib/rancher/k3s/agent/containerd` |
| `/dev/sda10` | 약 396GiB | `openebs` LVM physical volume |

```shell
# cpa
sudo install -D -m 644 /dev/stdin /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg <<'YAML'
network: {config: disabled}
YAML
sudo install -m 600 /dev/stdin /etc/netplan/50-cloud-init.yaml <<'YAML'
network:
  version: 2
  ethernets:
    ens3:
      dhcp4: false
      addresses:
        - 192.168.254.4/24
      routes:
        - to: default
          via: 192.168.254.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 1.1.1.1
      optional: true
YAML
sudo netplan generate
sudo netplan apply
ip -brief address show ens3
ip route show default
```

```shell
# cpa
sudo apt update -y
sudo apt install -y lvm2
printf '%s\n' dm_snapshot | sudo tee /etc/modules-load.d/openebs.conf >/dev/null
sudo modprobe dm_snapshot
lsmod | grep '^dm_snapshot '
sudo pvcreate /dev/sda10
sudo vgcreate openebs /dev/sda10
sudo pvs -o pv_name,vg_name,pv_size
sudo vgs -o vg_name,pv_count,vg_size
```

## C. K3s server

```shell
# cpa
if [ -x /usr/local/bin/k3s-uninstall.sh ]; then
  sudo /usr/local/bin/k3s-uninstall.sh
fi
```

관리자 컴퓨터에서 state의 server token을 CPA K3s configuration file에 mode `600`으로 저장한다.
Token은 화면에 출력하지 않는다.

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

```shell
# cpa
export CLUSTER='cpa'
export SERVER_IP='192.168.254.4'
export SERVICE_CIDR='172.31.128.0/17'
export CLUSTER_DNS_IP='172.31.128.10'
export OIDC_ISSUER='https://oidc.k3s.ghilbut.com/cpa'
export K3S_VERSION='v1.36.2+k3s1'

export INSTALL_K3S_EXEC="\
--cluster-dns $CLUSTER_DNS_IP \
--cluster-init \
--disable local-storage \
--disable traefik \
--disable-helm-controller \
--disable-kube-proxy \
--disable-network-policy \
--flannel-backend none \
--kube-apiserver-arg service-account-issuer=$OIDC_ISSUER \
--kube-apiserver-arg service-account-jwks-uri=$OIDC_ISSUER/openid/v1/jwks \
--kube-controller-manager-arg allocate-node-cidrs=false \
--kubelet-arg allowed-unsafe-sysctls=net.ipv4.* \
--node-name=$CLUSTER \
--service-cidr $SERVICE_CIDR"

curl -sfL https://get.k3s.io | sudo env \
  INSTALL_K3S_EXEC="$INSTALL_K3S_EXEC" \
  INSTALL_K3S_VERSION="$K3S_VERSION" \
  sh -
sudo systemctl is-active k3s
sudo k3s --version
```

## D. 관리자 kubeconfig

다음 명령은 `~/.kube/config`의 `cpa` cluster와 user를 새 K3s 인증 정보로 덮어쓴다.

```shell
# administrator computer
mkdir -p ~/.kube
KUBECONFIG_SOURCE=$(mktemp)
KUBECONFIG_NEW=$(mktemp)

ssh cpa 'sudo cat /etc/rancher/k3s/k3s.yaml' \
  | sed \
      -e 's#https://127.0.0.1:6443#https://192.168.254.4:6443#' \
      -e 's/name: default/name: cpa/g' \
      -e 's/cluster: default/cluster: cpa/g' \
      -e 's/user: default/user: cpa/g' \
      -e 's/current-context: default/current-context: cpa/' \
  > "$KUBECONFIG_SOURCE"

chmod 600 "$KUBECONFIG_SOURCE"
KUBECONFIG="$KUBECONFIG_SOURCE:$HOME/.kube/config" \
  kubectl config view --merge --flatten --raw > "$KUBECONFIG_NEW"
chmod 600 "$KUBECONFIG_NEW"
mv "$KUBECONFIG_NEW" ~/.kube/config
kubectl config use-context cpa
kubectl config view --minify --raw \
  -o jsonpath='{.contexts[0].context.cluster}{" "}{.contexts[0].context.user}{"\n"}'
kubectl get nodes -o wide
```

## E. etcd snapshot S3

정기 snapshot은 6시간마다 생성한다. Local filesystem에는 8개를 유지하고 S3에는 28개를
유지한다. Versioning 중단 전에 생성된 noncurrent version은 90일 동안 유지한다.

정기 snapshot은 `k3s-cpa-snapshot` IAM user의 access key를 사용한다. `k3s/tofu`는 access key와
`kube-system/k3s-etcd-snapshot-s3-config` Secret을 함께 관리한다. Access key와 server token은
민감한 OpenTofu state 값이다.

### 1. 정기 snapshot 설정

S3 configuration Secret을 사용할 때 K3s server에는 `etcd-s3`와 `etcd-s3-config-secret`만 S3
설정으로 지정한다. 다른 S3 설정은 모두 Secret에 둔다.

```shell
# cpa
sudo install -D -m 600 /dev/stdin \
  /etc/rancher/k3s/config.yaml.d/20-etcd-snapshot.yaml <<'YAML'
etcd-snapshot-compress: true
etcd-snapshot-schedule-cron: "0 */6 * * *"
etcd-snapshot-retention: 8
etcd-s3: true
etcd-s3-config-secret: k3s-etcd-snapshot-s3-config
YAML

sudo systemctl restart k3s
sudo systemctl is-active k3s
```

### 2. Server token 확인

State의 server token과 CPA의 `/var/lib/rancher/k3s/server/token`이 같은 password를 사용하는지
확인한다. Token은 화면에 출력하지 않는다.

```shell
# administrator computer
K3S_SERVER_TOKEN="$(tofu -chdir=k3s/tofu output -raw cpa_server_token)"
CPA_SERVER_TOKEN="$(ssh cpa 'sudo cat /var/lib/rancher/k3s/server/token')"
case "$CPA_SERVER_TOKEN" in
  K10*::server:*) CPA_SERVER_TOKEN="${CPA_SERVER_TOKEN##*:}" ;;
esac
test "$CPA_SERVER_TOKEN" = "$K3S_SERVER_TOKEN"
unset CPA_SERVER_TOKEN K3S_SERVER_TOKEN
```

## F. ServiceAccount OIDC와 AWS IAM federation

> [!info] 공통 절차
> ![[k3s/RUNBOOK#D. ServiceAccount OIDC와 AWS IAM federation]]

`k3s/tofu/tofu-apply.auto.tfvars`가 `tofu-apply` role ARN을 지정한 Apply 전용 로컬 작업 공간에서
실행한다. 이 Apply는 ServiceAccount OIDC object, snapshot access key와 S3 configuration Secret을
함께 관리한다.

```shell
# administrator computer
export AWS_SDK_LOAD_CONFIG=1
export AWS_PROFILE='ghilbut-tofu-apply-for-workloads'

tofu -chdir=k3s/tofu init -reconfigure \
  -backend-config=tofu-state-apply.tfbackend
tofu -chdir=k3s/tofu apply

kubectl --context cpa -n kube-system get secret \
  k3s-etcd-snapshot-s3-config \
  -o jsonpath='{.type}{"\n"}'

kubectl --context cpa get --raw '/.well-known/openid-configuration' \
  | jq -e \
      '.issuer == "https://oidc.k3s.ghilbut.com/cpa" and .jwks_uri == "https://oidc.k3s.ghilbut.com/cpa/openid/v1/jwks"'
curl --fail --silent --show-error \
  https://oidc.k3s.ghilbut.com/cpa/.well-known/openid-configuration \
  | jq -e \
      '.issuer == "https://oidc.k3s.ghilbut.com/cpa" and .jwks_uri == "https://oidc.k3s.ghilbut.com/cpa/openid/v1/jwks"'
diff \
  <(kubectl --context cpa get --raw '/openid/v1/jwks' | jq -S .) \
  <(curl --fail --silent --show-error \
    https://oidc.k3s.ghilbut.com/cpa/openid/v1/jwks | jq -S .)
```

## G. Snapshot 확인

수동 snapshot으로 local 저장과 S3 업로드를 함께 확인한다. `cpa-s3-check` snapshot은 정기
snapshot retention 대상이 아니므로 확인을 마친 뒤 이름을 지정하여 삭제한다.

```shell
# administrator computer
ssh cpa 'sudo k3s etcd-snapshot save --name cpa-s3-check'
ssh cpa 'sudo k3s etcd-snapshot ls' \
  | grep -F 's3://ghilbut-backups/k3s/cpa/'

kubectl --context cpa get etcdsnapshotfile \
  -l etcd.k3s.cattle.io/snapshot-storage-node=s3 \
  -o custom-columns=NAME:.metadata.name,SNAPSHOT:.spec.snapshotName,LOCATION:.spec.location,READY:.status.readyToUse,CREATED:.status.creationTime
```

표의 `READY`가 `true`이고 `LOCATION`이 `s3://ghilbut-backups/k3s/cpa/`로 시작해야 한다. 출력의
`SNAPSHOT` 값을 사용하여 확인용 snapshot을 삭제한다.

```shell
# cpa
export SNAPSHOT_NAME='<SNAPSHOT>'
sudo k3s etcd-snapshot delete "$SNAPSHOT_NAME"
sudo k3s etcd-snapshot ls
unset SNAPSHOT_NAME
```

삭제 뒤 목록에 지정한 `SNAPSHOT_NAME`이 없어야 한다.

## H. Cilium

```shell
# administrator computer
kubectl --context cpa taint nodes --all node.cilium.io/agent-not-ready=true:NoExecute
kubectl --context cpa apply -f \
  https://raw.githubusercontent.com/kubernetes-sigs/mcs-api/master/config/crd/multicluster.x-k8s.io_serviceexports.yaml
kubectl --context cpa apply -f \
  https://raw.githubusercontent.com/kubernetes-sigs/mcs-api/master/config/crd/multicluster.x-k8s.io_serviceimports.yaml

helm repo add cilium https://helm.cilium.io/
helm repo update
helm upgrade --kube-context cpa --install cilium cilium/cilium \
  --version 1.20.0 \
  --namespace kube-system \
  --values /dev/stdin <<'YAML'
k8sServiceHost: 192.168.254.4
k8sServicePort: 6443
ipam:
  operator:
    mode: cluster-pool
    clusterPoolIPv4MaskSize: 24
    clusterPoolIPv4PodCIDRList: 172.31.0.0/17
kubeProxyReplacement: true
socketLB:
  hostNamespaceOnly: true
cni:
  exclusive: false
l7Proxy: false
operator:
  replicas: 1
YAML

kubectl --context cpa rollout status daemonset/cilium -n kube-system --timeout=10m
kubectl --context cpa rollout status deployment/cilium-operator -n kube-system --timeout=10m
kubectl --context cpa get pods -A \
  -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,HOSTNETWORK:.spec.hostNetwork \
  --no-headers=true \
  | awk '$3 == "<none>" {print "-n " $1 " " $2}' \
  | xargs -r -L 1 kubectl --context cpa delete pod
kubectl --context cpa wait --for=condition=Ready node/cpa --timeout=10m
```

## I. Applications

CPA는 단일 control-plane cluster로 실행한다. Cilium node와 ServiceAccount OIDC issuer 검증을 마친 뒤 [[apps/runbooks/BOOTSTRAP|Bootstrap]]을 실행한다. CPA는 Argo CD를 설치하고, GPA는 CPA Argo CD의 관리 대상으로 등록한다.
