---
type: runbook
area: k3s
---

# K3s 설치 RUNBOOK

실행별 값과 실제 명령은 `runbooks/`에 기록한다.

## A. 공식 참고 문서

- [K3s server CLI](https://docs.k3s.io/cli/server): server 설치 옵션, embedded etcd, networking, packaged component 비활성화
- [K3s 제거](https://docs.k3s.io/installation/uninstall): server와 agent 제거 script의 영향 범위
- [Kubernetes ServiceAccount token projection과 issuer discovery](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/): issuer, discovery document, JWKS endpoint, public JWKS URI
- [LVM physical volume](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/8/html/configuring_and_managing_logical_volumes/managing-lvm-physical-volumes_configuring-and-managing-logical-volumes)과 [volume group](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/8/html/configuring_and_managing_logical_volumes/managing-lvm-volume-groups_configuring-and-managing-logical-volumes): `pvcreate`, `vgcreate`, `pvs`, `vgs`
- [Cilium Helm 설치](https://docs.cilium.io/en/stable/installation/k8s-install-helm/): Helm chart 설치와 node taint
- [Argo CD 설치](https://argo-cd.readthedocs.io/en/stable/operator-manual/installation/#helm): Helm chart 설치
- [Argo CD 초기 로그인](https://argo-cd.readthedocs.io/en/stable/getting_started/#4-login-using-the-cli): initial admin password와 password 변경
- [AWS IAM OIDC provider 생성](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html): issuer URL과 audience 설정

## B. 설치 값

설치 전에 다음 값을 확정한다. Service CIDR, Pod CIDR, 물리 네트워크 CIDR은 서로 겹치지 않는다. 실행 컴퓨터에는 `kubectl`과 `helm`이 있어야 한다.

| 항목 | 설명 |
| --- | --- |
| `CLUSTER` | Kubernetes context와 server node 이름 |
| `SERVER_IP` | control-plane의 고정 IPv4 주소 |
| `SERVICE_CIDR` | Kubernetes Service CIDR |
| `CLUSTER_DNS_IP` | `SERVICE_CIDR`에 속한 CoreDNS Service IP |
| `POD_CIDR` | Cilium cluster-pool Pod CIDR |
| `OIDC_ISSUER` | ServiceAccount issuer URL |
| `CILIUM_VERSION` | Cilium Helm chart 버전 |
| `OPENEBSD_DEVICE` | OpenEBS LVM physical volume으로 초기화할 미마운트 block device |
| `OPENEBSD_VG` | OpenEBS LVM volume group 이름 |

Argo CD를 설치하는 클러스터는 `ARGO_CD_VERSION`도 확정한다. token, kubeconfig 인증서, private key는 실행 문서와 저장소에 기록하지 않는다.

## C. Server

### 1. host 준비

K3s 데이터와 OpenEBS LVM physical volume은 서로 다른 block device 또는 파티션을 사용한다. `OPENEBSD_DEVICE`에는 파일시스템, mount, physical volume, volume group이 없어야 한다.

```shell
export CLUSTER='<CLUSTER>'
export SERVER_IP='<SERVER_IP>'
export SSH_USER='<SSH_USER>'
export OPENEBSD_DEVICE='<OPENEBSD_DEVICE>'
export OPENEBSD_VG='openebs'

ssh "$SSH_USER@$SERVER_IP"

sudo apt update -y
sudo apt full-upgrade -y
sudo apt install -y lvm2 qemu-guest-agent
sudo systemctl enable --now qemu-guest-agent
sudo systemctl is-active qemu-guest-agent
lsblk -o NAME,FSTYPE,SIZE,TYPE,MOUNTPOINTS
sudo wipefs -n "$OPENEBSD_DEVICE"
sudo pvs
sudo vgs
```

### 2. OpenEBS LVM volume group 생성

`pvcreate`는 대상 device의 기존 서명을 LVM metadata로 바꾼다. `wipefs -n`, `pvs`, `vgs` 결과가 대상 device가 비어 있음을 보여 줄 때만 실행한다.

```shell
sudo pvcreate "$OPENEBSD_DEVICE"
sudo vgcreate "$OPENEBSD_VG" "$OPENEBSD_DEVICE"
sudo pvs -o pv_name,vg_name,pv_size
sudo vgs -o vg_name,pv_count,vg_size
```

### 3. K3s server 설치

재설치는 기존 K3s 상태를 삭제한다. 기존 클러스터의 필요한 데이터는 재설치 전에 별도 백업한다.

```shell
export CLUSTER='<CLUSTER>'
export SERVER_IP='<SERVER_IP>'
export SERVICE_CIDR='<SERVICE_CIDR>'
export CLUSTER_DNS_IP='<CLUSTER_DNS_IP>'
export OIDC_ISSUER='<OIDC_ISSUER>'

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

K3s 설치 script는 stable channel의 최신 release를 설치한다. `k3s --version` 결과를 실행 문서에 기록한다.

### 4. 관리자 kubeconfig 갱신

서버의 `/etc/rancher/k3s/k3s.yaml`은 관리자 인증 정보를 포함한다. 다음 명령은 로컬 `~/.kube/config`의 `CLUSTER` cluster, user, context를 새 K3s 인증 정보로 바꾸고 다른 항목을 유지한다.

```shell
export CLUSTER='<CLUSTER>'
export SERVER_IP='<SERVER_IP>'

mkdir -p ~/.kube
KUBECONFIG_SOURCE=$(mktemp)
KUBECONFIG_NEW=$(mktemp)

ssh "$SSH_USER@$SERVER_IP" 'sudo cat /etc/rancher/k3s/k3s.yaml' \
  | sed \
      -e "s#https://127.0.0.1:6443#https://$SERVER_IP:6443#" \
      -e "s/name: default/name: $CLUSTER/g" \
      -e "s/cluster: default/cluster: $CLUSTER/g" \
      -e "s/user: default/user: $CLUSTER/g" \
      -e "s/current-context: default/current-context: $CLUSTER/" \
  > "$KUBECONFIG_SOURCE"

chmod 600 "$KUBECONFIG_SOURCE"
KUBECONFIG="$KUBECONFIG_SOURCE:$HOME/.kube/config" \
  kubectl config view --merge --flatten --raw > "$KUBECONFIG_NEW"
chmod 600 "$KUBECONFIG_NEW"
mv "$KUBECONFIG_NEW" ~/.kube/config
kubectl config use-context "$CLUSTER"
kubectl config view --minify --raw \
  -o jsonpath='{.contexts[0].context.cluster}{" "}{.contexts[0].context.user}{"\n"}'
kubectl get nodes -o wide
```

K3s가 CNI를 기다리는 동안 server node는 `NotReady`다. Cilium 설치 뒤 node `Ready`를 확인한다.

## D. ServiceAccount OIDC와 AWS IAM federation

K3s server는 `service-account-issuer`와 `service-account-jwks-uri`로 ServiceAccount token의 issuer와 공개 JWKS URL을 설정한다. Kubernetes API server는 `/.well-known/openid-configuration`과 `/openid/v1/jwks`를 제공한다. CPA의 CDN은 이 두 응답을 `${OIDC_ISSUER}` 경로로 공개한다.

공개 endpoint는 discovery document와 JWKS만 제공한다. ServiceAccount token, Kubernetes Secret, token 서명 private key는 공개하지 않는다. Pod는 TokenRequest API가 발급한 짧은 수명의 projected ServiceAccount token을 사용한다.

### 1. CPA 공개 issuer 동기화

CPA의 `k3s/tofu`는 Kubernetes API에서 discovery document와 JWKS를 읽어 CDN origin object로 동기화하고, `https://oidc.k3s.ghilbut.com/cpa` IAM OIDC provider를 관리한다.

```shell
tofu -chdir=k3s/tofu init
tofu -chdir=k3s/tofu plan
tofu -chdir=k3s/tofu apply
```

### 2. AWS IAM federation 경계

AWS 계정은 cluster issuer당 IAM OIDC provider를 하나 사용한다. IAM role은 workload별로 분리하고, 각 role의 trust policy에는 다음 값을 모두 지정한다.

1. `sts:AssumeRoleWithWebIdentity` action
2. audience `sts.amazonaws.com`
3. 정확한 `system:serviceaccount:<namespace>:<serviceaccount>` subject

CPA OIDC provider의 TLS intermediate CA SHA-1 thumbprint는 `k3s/tofu`의 `cpa_oidc_thumbprint`로 관리한다.

### 3. 확인

```shell
export CLUSTER='<CLUSTER>'
export OIDC_ISSUER='<OIDC_ISSUER>'

kubectl --context "$CLUSTER" get --raw '/.well-known/openid-configuration' \
  | jq -e --arg issuer "$OIDC_ISSUER" \
      '.issuer == $issuer and .jwks_uri == ($issuer + "/openid/v1/jwks")'
kubectl --context "$CLUSTER" get --raw '/openid/v1/jwks' \
  | jq -e '.keys | length > 0'
curl --fail --silent --show-error \
  "$OIDC_ISSUER/.well-known/openid-configuration" \
  | jq -e --arg issuer "$OIDC_ISSUER" \
      '.issuer == $issuer and .jwks_uri == ($issuer + "/openid/v1/jwks")'
diff \
  <(kubectl --context "$CLUSTER" get --raw '/openid/v1/jwks' | jq -S .) \
  <(curl --fail --silent --show-error "$OIDC_ISSUER/openid/v1/jwks" | jq -S .)
```

## E. Cilium 최소 구성

CNI가 없으면 Helm Controller Job도 실행하지 못한다. Cilium은 Helm CLI로 먼저 설치한다.

```shell
export CLUSTER='<CLUSTER>'
export SERVER_IP='<SERVER_IP>'
export POD_CIDR='<POD_CIDR>'
export CILIUM_VERSION='<CILIUM_VERSION>'

kubectl --context "$CLUSTER" taint nodes --all \
  node.cilium.io/agent-not-ready=true:NoExecute
kubectl --context "$CLUSTER" apply -f \
  https://raw.githubusercontent.com/kubernetes-sigs/mcs-api/master/config/crd/multicluster.x-k8s.io_serviceexports.yaml
kubectl --context "$CLUSTER" apply -f \
  https://raw.githubusercontent.com/kubernetes-sigs/mcs-api/master/config/crd/multicluster.x-k8s.io_serviceimports.yaml

helm repo add cilium https://helm.cilium.io/
helm repo update
helm upgrade --kube-context "$CLUSTER" --install cilium cilium/cilium \
  --version "$CILIUM_VERSION" \
  --namespace kube-system \
  --values /dev/stdin <<YAML
k8sServiceHost: $SERVER_IP
k8sServicePort: 6443
ipam:
  operator:
    mode: cluster-pool
    clusterPoolIPv4MaskSize: 24
    clusterPoolIPv4PodCIDRList: $POD_CIDR
kubeProxyReplacement: true
l7Proxy: false
operator:
  replicas: 1
YAML

kubectl --context "$CLUSTER" rollout status daemonset/cilium \
  -n kube-system --timeout=10m
kubectl --context "$CLUSTER" rollout status deployment/cilium-operator \
  -n kube-system --timeout=10m
kubectl --context "$CLUSTER" get pods -A \
  -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,HOSTNETWORK:.spec.hostNetwork \
  --no-headers=true \
  | awk '$3 == "<none>" {print "-n " $1 " " $2}' \
  | xargs -r -L 1 kubectl --context "$CLUSTER" delete pod
kubectl --context "$CLUSTER" wait --for=condition=Ready node \
  --all --timeout=10m
```

## F. Optional: Argo CD 최소 구성

Argo CD는 모든 클러스터에 설치하지 않는다. GitOps 관리가 필요한 클러스터만 이 절차를 실행한다. 이 구성은 Dex와 notifications를 사용하지 않는다.

```shell
export CLUSTER='<CLUSTER>'
export ARGO_CD_VERSION='<ARGO_CD_VERSION>'

kubectl --context "$CLUSTER" create namespace argo
kubectl --context "$CLUSTER" apply -f - <<'YAML'
apiVersion: v1
kind: Secret
metadata:
  name: argocd-secret
  namespace: argo
type: Opaque
YAML

helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm upgrade --kube-context "$CLUSTER" --install cd argo/argo-cd \
  --version "$ARGO_CD_VERSION" \
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

kubectl --context "$CLUSTER" get pods -n argo
```

### 1. Admin password

새 admin password는 실행자가 대화형 prompt에 입력한다. `argocd-initial-admin-secret`의 password를 직접 사용한다. password와 Argo CD authentication token은 실행 문서와 저장소에 기록하지 않는다.

```shell
argocd login \
  --name "$CLUSTER" \
  --password "$(kubectl --context "$CLUSTER" -n argo get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 --decode)" \
  --username admin \
  --grpc-web-root-path /cd \
  --insecure \
  --kube-context "$CLUSTER" \
  --plaintext \
  --port-forward \
  --port-forward-namespace argo

argocd account update-password \
  --argocd-context "$CLUSTER" \
  --kube-context "$CLUSTER" \
  --port-forward \
  --port-forward-namespace argo

kubectl --context "$CLUSTER" -n argo \
  delete secret argocd-initial-admin-secret
argocd logout "$CLUSTER"
```

### 2. Local UI

```shell
kubectl --context "$CLUSTER" -n argo port-forward service/cd-server 8080:80
```

`http://localhost:8080/cd`는 `http://localhost:8080/cd/`로 redirect한다. 별도 terminal에서 다음 명령으로 응답을 확인한다.

```shell
curl --fail --silent --show-error --output /dev/null \
  --write-out '%{http_code} %{redirect_url}\n' \
  http://localhost:8080/cd
```

## G. Optional: Agent

Agent는 모든 클러스터에 설치하지 않는다. 추가 workload node가 필요한 클러스터만 이 절차를 실행한다. agent host는 server와 같은 Ubuntu 준비 절차를 수행한다. agent에는 `/var/lib/kubelet`, `/var/lib/rancher`, `/var/lib/rancher/k3s/agent/containerd` 파일시스템을 사용한다. embedded etcd 전용인 `/var/lib/rancher/k3s/server/db`는 agent에 만들지 않는다.

```shell
# control-plane
sudo cat /var/lib/rancher/k3s/server/node-token
```

```shell
# agent
export CLUSTER='<CLUSTER>'
export SERVER_IP='<SERVER_IP>'
export AGENT_NAME='<AGENT_NAME>'
export AGENT_IP='<AGENT_IP>'
export K3S_TOKEN='<control-plane node token>'

export INSTALL_K3S_EXEC="\
agent \
--server https://$SERVER_IP:6443 \
--node-name $AGENT_NAME \
--node-ip $AGENT_IP \
--kubelet-arg allowed-unsafe-sysctls=net.ipv4.*"

curl -sfL https://get.k3s.io | sh -
sudo systemctl is-active k3s-agent
sudo k3s --version
```

```shell
# administrator computer
kubectl --context "$CLUSTER" get nodes -o wide
kubectl --context "$CLUSTER" get pods -n kube-system \
  -l k8s-app=cilium -o wide
```

## H. 실행 Runbook

실행 전 `runbooks/<CLUSTER>.md`를 작성한다. 이 문서는 해당 클러스터의 실제 값, 순서대로 실행할 전체 shell command, 검증 결과를 포함한다.

실행 Runbook은 다음 properties를 사용한다.

| Property | 값 |
| --- | --- |
| `type` | `run` |
| `area` | `k3s` |
| `cluster` | 클러스터 이름 |
| `status` | `planned`, `failed`, `completed` 중 하나 |
| `planned_at` | 계획 작성일, `YYYY-MM-DD` |
| `completed_at` | 설치 완료일, `YYYY-MM-DD` |

실행 중인 문서는 `status: planned`를 사용한다. 설치를 마친 문서는 `status: completed`와 `completed_at`을 기록한다. 실패한 문서는 `status: failed`와 발생 위치 및 관찰 결과를 기록한다.
