---
type: runbook
area: k3s
---

# K3s 설치 RUNBOOK

- [A. Common](#a-common)
- [B. Server](#b-server)
- [C. Agent](#c-agent)

문서 규칙: [RULEBOOK](RULEBOOK.md)

## A. Common

### 1. 설치 값

실행 기록에서 아래 값을 확정한다. CIDR이나 URL이 확정되지 않은 클러스터는 설치하지 않는다.

| 항목 | 설명 |
| --- | --- |
| CLUSTER | Kubernetes context와 K3s node name. 예: cpa |
| SERVER_IP | control-plane의 고정 IPv4 주소 |
| SERVICE_CIDR | Kubernetes Service CIDR |
| CLUSTER_DNS_IP | SERVICE_CIDR 안의 CoreDNS Service IP |
| POD_CIDR | Cilium cluster-pool Pod CIDR. Service CIDR과 겹치지 않아야 함 |
| OIDC_ISSUER | K3s ServiceAccount issuer URL |
| HOST_DISK_LAYOUT | 파일시스템별 용량과 OpenEBS LVM용 미마운트 영역 |
| AGENTS | agent별 node name, 고정 IP, label, taint |
| K3S_VERSION | 설치 후 k3s --version으로 기록하는 참고 값. 설치 시 지정하지 않음 |
| CILIUM_VERSION | Helm chart 버전 |

다음을 확인한다. 값 표의 모든 값을 실행 기록에 채운 뒤, 아래 명령의 꺾쇠괄호 값을 해당 값으로 바꾼다.

- SERVER_IP:6443에 관리자 컴퓨터와 모든 agent가 연결할 수 있다.
- SERVICE_CIDR, POD_CIDR, 물리 네트워크 CIDR가 겹치지 않는다.
- 관리자 컴퓨터에 kubectl과 helm이 있다.

실행 기록에는 실제 버전, host 사양, CIDR, issuer URL, 수행 시각, 검증 결과와 보류 항목만 기록한다. token과 kubeconfig 인증서·private key는 기록하지 않는다.

## B. Server

[K3s Server configuration options](https://docs.k3s.io/cli/server)

### 1. server host와 Ubuntu 준비

server는 물리 장비 또는 VM으로 준비할 수 있다. 실행 기록에는 host 유형, 이름, CPU, 메모리, 디스크, 고정 IP를 적는다. K3s에는 별도 파일시스템을 사용한다.

| 경로 | 용도 |
| --- | --- |
| /var/lib/kubelet | kubelet 상태와 볼륨 마운트 |
| /var/lib/rancher | K3s 데이터 루트 |
| /var/lib/rancher/k3s/server/db | embedded etcd 데이터 |
| /var/lib/rancher/k3s/agent/containerd | containerd 이미지와 레이어 |
| 미마운트 영역 | OpenEBS LVM의 PV 영역 |

Ubuntu 설치 후 SSH 공개키 로그인을 설정하고 상태를 확인한다.

```shell
export CLUSTER='<CLUSTER>'
export SERVER_IP='<SERVER_IP>'
export SSH_USER='<SSH_USER>'
export SSH_IDENTITY_FILE="$HOME/.ssh/id_ed25519"
export KUBECONFIG_PATH="$HOME/.kube/$CLUSTER.yaml"

ssh-copy-id -i "$SSH_IDENTITY_FILE.pub" "$SSH_USER@$SERVER_IP"
ssh "$SSH_USER@$SERVER_IP"

sudo apt update -y
sudo apt full-upgrade -y
sudo apt install -y qemu-guest-agent
sudo systemctl enable --now qemu-guest-agent
sudo systemctl is-active qemu-guest-agent
lsblk -o NAME,FSTYPE,SIZE,TYPE,MOUNTPOINTS
```

관리자 kubeconfig를 원격에서 읽으려면 SSH 사용자가 sudo를 비밀번호 없이 실행할 수 있어야 한다. 사용자별 sudoers 파일을 만들고 문법을 검증한다.

```shell
echo "$SSH_USER ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee "/etc/sudoers.d/$SSH_USER" >/dev/null
sudo chmod 440 "/etc/sudoers.d/$SSH_USER"
sudo visudo -cf "/etc/sudoers.d/$SSH_USER"
```

### 2. K3s server 설치

다음은 control-plane에서 실행한다.

```shell
export CLUSTER='<CLUSTER>'
export SERVER_IP='<SERVER_IP>'
export SERVICE_CIDR='<SERVICE_CIDR>'
export CLUSTER_DNS_IP='<CLUSTER_DNS_IP>'
export OIDC_ISSUER='https://oidc.k3s.ghilbut.com/<CLUSTER>'

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
sudo journalctl -u k3s -n 100 --no-pager
sudo k3s --version
```

서버의 /etc/rancher/k3s/k3s.yaml에는 관리자 인증서와 private key가 있다. 저장소에 넣지 않는다. 인증서는 갱신될 수 있으므로 원격 kubeconfig가 동작하지 않으면 서버에서 최신 파일을 다시 복사한다.

```shell
mkdir -p ~/.kube
ssh "$SSH_USER@$SERVER_IP" 'sudo cat /etc/rancher/k3s/k3s.yaml' \
  | sed "s#https://127.0.0.1:6443#https://$SERVER_IP:6443#" \
  > "$KUBECONFIG_PATH"
chmod 600 "$KUBECONFIG_PATH"
KUBECONFIG="$KUBECONFIG_PATH" kubectl config rename-context default "$CLUSTER"
KUBECONFIG="$KUBECONFIG_PATH" kubectl get nodes
```

CNI 이전의 NotReady는 예상되는 상태다. Cilium 설치 후 Ready를 확인한다.

### 3. Cilium 설치

CNI가 없으면 Helm Controller Job도 실행되지 않으므로 Cilium은 Helm CLI로 먼저 설치한다.

```shell
export KUBECONFIG="$KUBECONFIG_PATH"
export POD_CIDR='<POD_CIDR>'
export CILIUM_VERSION='<CILIUM_VERSION>'
export CILIUM_SERVICE_PORT='6443'
export CILIUM_POD_MASK_SIZE='24'
export CILIUM_OPERATOR_REPLICAS='1'

kubectl taint nodes --all node.cilium.io/agent-not-ready=true:NoExecute
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/mcs-api/master/config/crd/multicluster.x-k8s.io_serviceexports.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/mcs-api/master/config/crd/multicluster.x-k8s.io_serviceimports.yaml

helm repo add cilium https://helm.cilium.io/
helm repo update
helm upgrade --install cilium cilium/cilium \
  --version "$CILIUM_VERSION" \
  --namespace kube-system \
  --values /dev/stdin <<YAML
k8sServiceHost: $SERVER_IP
k8sServicePort: $CILIUM_SERVICE_PORT
ipam:
  operator:
    mode: cluster-pool
    clusterPoolIPv4MaskSize: $CILIUM_POD_MASK_SIZE
    clusterPoolIPv4PodCIDRList: $POD_CIDR
kubeProxyReplacement: true
l7Proxy: false
operator:
  replicas: $CILIUM_OPERATOR_REPLICAS
YAML

kubectl rollout status daemonset/cilium -n kube-system --timeout=10m
kubectl rollout status deployment/cilium-operator -n kube-system --timeout=10m
kubectl get nodes
kubectl get pods -A
```

CoreDNS 또는 metrics-server가 CNI 이전에 Pending으로 생성됐다면 삭제해 다시 생성한다.

```shell
kubectl get pods -A \
  -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,HOSTNETWORK:.spec.hostNetwork \
  --no-headers=true \
  | awk '$3 == "<none>" {print "-n " $1 " " $2}' \
  | xargs -r -L 1 kubectl delete pod
```

K3s server 설치는 server 노드가 Ready이고 Cilium DaemonSet과 Operator가 준비되면 완료다.

## C. Agent

[K3s Agent configuration options](https://docs.k3s.io/cli/agent)

### 1. K3s agent 설치

agent host도 [B. Server](#b-server)의 Ubuntu 준비 절차를 수행한다. agent에는 /var/lib/kubelet, /var/lib/rancher, /var/lib/rancher/k3s/agent/containerd 파일시스템을 구성한다. embedded etcd 전용인 /var/lib/rancher/k3s/server/db는 agent에 만들지 않는다.

control-plane에서 join token을 읽는다. token은 실행 기록과 저장소에 기록하지 않는다.

```shell
# control-plane
sudo cat /var/lib/rancher/k3s/server/node-token
```

각 agent에서 다음 공통 설정을 실행한다.

```shell
# agent
export CLUSTER='<CLUSTER>'
export SERVER_IP='<SERVER_IP>'
export AGENT_NAME='<AGENT_NAME>'
export AGENT_IP='<AGENT_IP>'
export K3S_TOKEN='<token from control-plane>'

export INSTALL_K3S_EXEC="\
agent \
--server https://$SERVER_IP:6443 \
--node-name $AGENT_NAME \
--node-ip $AGENT_IP \
--kubelet-arg allowed-unsafe-sysctls=net.ipv4.*"
```

일반 workload agent는 다음 명령을 실행한다.

```shell
curl -sfL https://get.k3s.io | sh -
```

역할 전용 agent는 label과 taint를 추가한 뒤 설치한다. 일반 workload agent에는 이 명령을 실행하지 않는다.

```shell
export AGENT_LABEL='node-role.example.io/gateway=true'
export AGENT_TAINT='node-role.example.io/gateway=true:NoSchedule'

export INSTALL_K3S_EXEC="$INSTALL_K3S_EXEC \
--node-label $AGENT_LABEL \
--node-taint $AGENT_TAINT"
curl -sfL https://get.k3s.io | sh -
```

각 agent에서 설치 후 상태를 확인한다.

```shell
sudo systemctl is-active k3s-agent
sudo journalctl -u k3s-agent -n 100 --no-pager
sudo k3s --version
```

관리자 컴퓨터에서 노드 등록과 Cilium Pod 배치를 확인한다.

```shell
KUBECONFIG="$KUBECONFIG_PATH" kubectl get nodes -o wide
KUBECONFIG="$KUBECONFIG_PATH" kubectl get pods -n kube-system -l k8s-app=cilium -o wide
```

agent 설치는 대상 agent가 Ready이고 해당 agent의 Cilium Pod가 Ready이면 완료다.
