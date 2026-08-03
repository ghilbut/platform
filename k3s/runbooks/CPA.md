---
type: run
area: k3s
cluster: cpa
status: completed
completed_at: 2026-08-03
---

# CPA K3s 재설치

CPA는 단일 control-plane K3s 클러스터다. 이 문서는 2026-08-03에 실행한 명령과 값을 기록한다. 인증 정보와 token은 기록하지 않는다.

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
| Cilium chart | `1.19.3` |
| Argo CD chart | `9.5.13` |
| OpenEBS LVM device | `/dev/sda10` |
| OpenEBS LVM volume group | `openebs` |

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
sudo apt update -y
sudo apt install -y lvm2
sudo pvcreate /dev/sda10
sudo vgcreate openebs /dev/sda10
sudo pvs -o pv_name,vg_name,pv_size
sudo vgs -o vg_name,pv_count,vg_size
```

결과: `/dev/sda10`은 `openebs` volume group의 유일한 physical volume이며 volume group 크기는 약 396GiB다.

## C. K3s server

```shell
# cpa
export CLUSTER='cpa'
export SERVER_IP='192.168.254.4'
export SERVICE_CIDR='172.31.128.0/17'
export CLUSTER_DNS_IP='172.31.128.10'
export OIDC_ISSUER='https://oidc.k3s.ghilbut.com/cpa'

if [ -x /usr/local/bin/k3s-uninstall.sh ]; then
  sudo /usr/local/bin/k3s-uninstall.sh
fi

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

curl -sfL https://get.k3s.io | sh -
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

결과: `cpa` context는 `cpa` cluster와 `cpa` user를 사용한다.

## E. ServiceAccount OIDC와 AWS IAM federation

> [!info] 공통 절차
> ![[k3s/RUNBOOK#D. ServiceAccount OIDC와 AWS IAM federation]]

```shell
# administrator computer
tofu -chdir=k3s/tofu init
tofu -chdir=k3s/tofu apply

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

K3s server에는 CPA issuer와 공개 JWKS URL을 적용했다. `tofu -chdir=k3s/tofu apply`는 공개 JWKS를 새 K3s 서명 키로 동기화했다. Kubernetes API와 공개 issuer의 discovery document, JWKS `diff`가 성공했다.

## F. Cilium

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
  --version 1.19.3 \
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

결과: cpa node, Cilium DaemonSet, Cilium Operator, CoreDNS, metrics-server가 Ready다.

## G. Optional: Argo CD

> [!info] 공통 절차
> ![[k3s/RUNBOOK#F. Optional: Argo CD 최소 구성]]

CPA는 GitOps 관리에 Argo CD를 사용하므로 이 optional 절차를 실행한다.

```shell
# administrator computer
kubectl --context cpa create namespace argo
kubectl --context cpa apply -f - <<'YAML'
apiVersion: v1
kind: Secret
metadata:
  name: argocd-secret
  namespace: argo
type: Opaque
YAML

helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm upgrade --kube-context cpa --install cd argo/argo-cd \
  --version 9.5.13 \
  --namespace argo \
  --wait \
  --timeout 10m \
  --values /dev/stdin <<'YAML'
fullnameOverride: cd
global:
  logging:
    level: warn
configs:
  cm:
    application.resourceTrackingMethod: annotation+label
  params:
    server.insecure: true
    server.basehref: /cd
    server.rootpath: /cd
  secret:
    createSecret: false
dex:
  enabled: false
notifications:
  enabled: false
YAML
```

### 1. Admin password

새 admin password는 실행자가 대화형 prompt에 입력한다. 다음 전체 block은 `argocd admin initial-password`의 첫 행으로 로그인한 뒤 password를 변경한다. `argocd account update-password`는 현재 password, 새 password, 새 password 확인을 차례로 요청한다. password와 authentication token은 이 실행 Runbook에 기록하지 않는다.

```shell
argocd login \
  --name cpa \
  --password "$(argocd admin initial-password --context cpa -n argo | sed -n '1p')" \
  --username admin \
  --grpc-web-root-path /cd \
  --insecure \
  --kube-context cpa \
  --plaintext \
  --port-forward \
  --port-forward-namespace argo

argocd account update-password \
  --argocd-context cpa \
  --kube-context cpa \
  --port-forward \
  --port-forward-namespace argo

kubectl --context cpa -n argo delete secret argocd-initial-admin-secret
argocd logout cpa
```

### 2. Local UI

```shell
kubectl --context cpa -n argo port-forward service/cd-server 8080:80
```

별도 terminal에서 `http://localhost:8080/cd`의 HTTP 응답을 확인한다.

```shell
curl --fail --silent --show-error --output /dev/null \
  --write-out '%{http_code} %{redirect_url}\n' \
  http://localhost:8080/cd
```

결과: `307 http://localhost:8080/cd/`.

## H. Optional: Agent

> [!info] 공통 절차
> ![[k3s/RUNBOOK#G. Optional: Agent]]

CPA는 단일 control-plane cluster로 실행하므로 agent를 설치하지 않는다.

## I. 완료 결과

| 확인 항목 | 결과 |
| --- | --- |
| K3s server | `v1.36.2+k3s1`, active |
| cpa node | Ready |
| Cilium | chart `1.19.3`, DaemonSet과 Operator Ready |
| Argo CD, optional | chart `9.5.13`, 모든 운영 Pod Running |
| OpenEBS LVM | `/dev/sda10` → `openebs`, 약 396GiB |
| Argo CD local URL | `http://localhost:8080/cd` → `/cd/` HTTP 307 |
| ServiceAccount OIDC | issuer, 공개 discovery document, JWKS 일치 |
| Agent, optional | 설치하지 않음 |
