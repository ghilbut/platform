---
type: runbook
area: apps
cluster: cpa
---

# Applications 설치

## 설치 순서

Agent가 다음 순서로 설치를 수행한다.

| 순서 | 애플리케이션 | 수동 작업 |
| --- | --- | --- |
| 1 | [[#1. Argo CD Application bootstrap\|Argo CD Application bootstrap]] | 없음 |
| 2 | [[#2. Istio system과 Argo CD sidecar\|Istio system과 Argo CD sidecar]] | 없음 |
| 3 | [[#3. OpenEBS LVM\|OpenEBS LVM]] | 없음 |
| 4 | [[#4. CoreDNS\|CoreDNS]] | ASUS Router DNS 변경 |
| 5 | [[#5. external-dns\|external-dns]] | 없음 |
| 6 | [[#6. cert-manager\|cert-manager]] | 없음 |
| 7 | [[#7. Istio Gateways\|Istio Gateways]] | 없음 |
| 8 | [[#8. Private Gateway와 Argo CD route\|Private Gateway와 Argo CD route]] | 없음 |

| 애플리케이션 | 역할 | 사용자 URL |
| --- | --- | --- |
| Argo CD | GitOps 관리 | `https://argo.ghilbut.com/cd` |
| Istio system | 서비스 메시 control plane | — |
| Istio gateways | ingress와 egress traffic 처리 | — |
| OpenEBS LVM | local persistent volume | — |
| CoreDNS | `ghilbut.com`, `ghilbut.net` DNS | — |
| external-dns | DNS record 관리 | — |
| cert-manager | TLS certificate 관리 | — |

## Pod Security Standards

![[knowledge/rulebooks/k8s/SECURITY#Pod Security Standards]]

## A. 사전 확인

[[k3s/runbooks/CPA|CPA K3s 재설치 Runbook]]가 `cpa` context, K3s, Cilium, Argo CD 기본 설치와 `openebs` volume group을 준비한 뒤에 이 Runbook을 실행한다.

```shell
kubectl --context cpa get nodes
kubectl --context cpa -n argo get deployment,statefulset,pod
kubectl --context cpa -n argo get secret argocd-initial-admin-secret
```

## B. 설치 순서

### 1. Argo CD Application bootstrap

[Argo CD Application specification](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/)을 참고한다.

`argo-apps` Application을 적용한다. 이 명령 뒤에 `argocd app sync` 또는 Application의 `operation.sync`를 실행하지 않는다. `argo-apps`의 automated sync는 child Application 리소스를 생성한다. child Application은 명시적 sync 전까지 workload를 생성하지 않는다.

```shell
kubectl --context cpa apply -f apps/argo-apps/argo-apps.yaml
kubectl --context cpa -n argo get application argo-apps
kubectl --context cpa -n argo get applications
```

### 2. Istio system과 Argo CD sidecar

[Istio sidecar injection](https://istio.io/latest/docs/setup/additional-setup/sidecar-injection/)과 [Istiod Helm chart values](https://raw.githubusercontent.com/istio/istio/1.30.3/manifests/charts/istio-control/istio-discovery/values.yaml)를 참고한다.

다음 Namespace를 제외하고 항상 sidecar를 주입한다.

- `kube-system`
- `kube-public`
- `kube-node-lease`
- `local-path-storage`
- `istio-system`

`istio-system`을 sync한 뒤 Argo CD Deployment와 StatefulSet을 재배포한다. 각 Argo CD Pod의 restartable init container에 `istio-proxy`가 있어야 한다.

```shell
argocd app sync istio-system \
  --kube-context cpa \
  --port-forward \
  --port-forward-namespace argo \
  --plaintext
kubectl --context cpa -n argo rollout restart deployment,statefulset
kubectl --context cpa -n argo rollout status deployment,statefulset --timeout=10m
kubectl --context cpa -n argo get pods -o json \
  | jq -r '.items[] | [.metadata.name, ([.spec.initContainers[].name] | join(","))] | @tsv'
```

### 3. OpenEBS LVM

[OpenEBS LVM 설치](https://openebs.io/docs/4.0.x/user-guides/local-storage-user-guide/local-pv-lvm/lvm-installation), [OpenEBS LVM StorageClass](https://openebs.io/docs/4.0.x/user-guides/local-storage-user-guide/local-pv-lvm/lvm-configuration), [Istio sidecar injection](https://istio.io/latest/docs/setup/additional-setup/sidecar-injection/)을 참고한다.

#### 설치 값

| 항목 | 값 |
| --- | --- |
| StorageClass | `openebs-lvm` |
| LVM volume group | `openebs` |
| Istio sidecar | disabled |
| Pod Security enforce | `privileged` |
| Pod Security audit, warn | `restricted` |

[[k3s/runbooks/CPA#B. host와 OpenEBS LVM|CPA OpenEBS LVM 선행 구성]]이 `lvm2`, `dm_snapshot` kernel module, `openebs` volume group을 준비한 뒤 `ebs`를 sync한다. OpenEBS LVM controller와 node Pod, `openebs-lvm` StorageClass를 확인한다.

OpenEBS LVM node Pod는 host device와 kubelet directory에 접근한다. `ebs` Namespace는 Istio sidecar 주입을 비활성화하고 `privileged`를 enforce하며 `restricted`를 audit과 warn으로 적용한다.

```shell
argocd app sync ebs \
  --kube-context cpa \
  --port-forward \
  --port-forward-namespace argo \
  --plaintext \
  --timeout 1200
argocd app wait ebs \
  --sync \
  --health \
  --kube-context cpa \
  --port-forward \
  --port-forward-namespace argo \
  --plaintext \
  --timeout 1200
kubectl --context cpa get storageclass openebs-lvm \
  -o jsonpath='{.provisioner}{"\t"}{.parameters.volgroup}{"\n"}'
```

### 4. CoreDNS

`coredns`를 sync하여 CPA host에서 private DNS를 제공한다. DNS record는 전용 etcd에 저장한다. [CoreDNS etcd plugin](https://coredns.io/plugins/etcd/)을 참고한다.

#### etcd

CPA host의 DNS와 etcd listener를 확인한 뒤 CoreDNS와 etcd가 Ready인 상태에서 DNS zone을 조회한다.

```shell
ssh cpa 'sudo ss -lntup | grep -E ":(53|2379|2380)\\b" || true'
argocd app sync coredns \
  --kube-context cpa \
  --port-forward \
  --port-forward-namespace argo \
  --plaintext \
  --timeout 1200
argocd app wait coredns \
  --sync \
  --health \
  --kube-context cpa \
  --port-forward \
  --port-forward-namespace argo \
  --plaintext \
  --timeout 1200
kubectl --context cpa -n coredns wait \
  --for=jsonpath='{.status.phase}'=Bound \
  persistentvolumeclaim/data-etcd-0 \
  --timeout=10m
dig @192.168.254.4 ghilbut.com SOA
dig @192.168.254.4 ghilbut.net SOA
```

설치가 완료되면 사용자가 ASUS Router의 DNS server를 `192.168.254.4`로 변경한다.

ASUS Router 설정을 적용한 뒤 LAN 클라이언트의 네트워크를 다시 연결하고 다음 명령을 실행한다.

```shell
dig ghilbut.com SOA
```

출력의 `SERVER`가 `192.168.254.4#53(192.168.254.4)`이면 LAN 클라이언트가 CoreDNS를 기본 DNS server로 사용한다.

### 5. external-dns

[ExternalDNS Istio source](https://kubernetes-sigs.github.io/external-dns/latest/docs/sources/istio/)와 [ExternalDNS target annotation](https://kubernetes-sigs.github.io/external-dns/latest/docs/annotations/annotations/#external-dnsalpha-kubernetes-io-target)을 참고한다.

#### 설치 값

| 항목 | 값 |
| --- | --- |
| DNS zones | `ghilbut.com`, `ghilbut.net` |
| Public DNS target | `ghilbut.asuscomm.com` |
| Private DNS target | `192.168.254.4` |

external-dns IAM role과 Route 53 권한을 적용한 뒤 `external-dns`를 sync한다. public Gateway는 `ghilbut.asuscomm.com` CNAME target을 사용한다. private Gateway는 `192.168.254.4` A record target을 사용한다.

```shell
tofu -chdir=apps/tofu init
tofu -chdir=apps/tofu plan
tofu -chdir=apps/tofu apply
kubectl --context cpa -n argo patch application external-dns \
  --type=merge \
  --patch '{"operation":{"sync":{"prune":true}}}'
kubectl --context cpa -n argo wait \
  --for=jsonpath='{.status.operationState.phase}'=Succeeded \
  application/external-dns \
  --timeout=20m
kubectl --context cpa -n external-dns logs deployment/external-dns --tail=100
```

### 6. cert-manager

[cert-manager Route 53 DNS-01](https://cert-manager.io/docs/configuration/acme/dns01/route53/)을 참고한다.

#### 설치 값

| 항목 | 값 |
| --- | --- |
| Certificate DNS name | `argo.ghilbut.com` |
| Route 53 hosted zones | `ghilbut.com`, `ghilbut.net` |

cert-manager IAM role과 Route 53 DNS-01 권한을 적용한 뒤 `cert-manager`를 sync한다. `argo.ghilbut.com` Certificate가 Ready인지 확인한다.

```shell
tofu -chdir=apps/tofu init
tofu -chdir=apps/tofu plan
tofu -chdir=apps/tofu apply
kubectl --context cpa -n argo patch application cert-manager \
  --type=merge \
  --patch '{"operation":{"sync":{"prune":true}}}'
kubectl --context cpa -n argo wait \
  --for=jsonpath='{.status.operationState.phase}'=Succeeded \
  application/cert-manager \
  --timeout=20m
kubectl --context cpa -n istio-gateways wait \
  --for=condition=Ready certificate/argo-https \
  --timeout=20m
```

### 7. Istio Gateways

[Istio gateway 설치](https://istio.io/latest/docs/setup/additional-setup/gateway/)를 참고한다.

`istio-gateways`를 sync한다. ingress와 egress gateway Deployment가 Available인지 확인한다.

```shell
kubectl --context cpa -n argo patch application istio-gateways \
  --type=merge \
  --patch '{"operation":{"sync":{"prune":true}}}'
kubectl --context cpa -n argo wait \
  --for=jsonpath='{.status.operationState.phase}'=Succeeded \
  application/istio-gateways \
  --timeout=20m
kubectl --context cpa -n istio-gateways get deployment,service,gateway
```

### 8. Private Gateway와 Argo CD route

[Istio traffic management](https://istio.io/latest/docs/concepts/traffic-management/)를 참고한다.

#### 설치 값

| 항목 | 값 |
| --- | --- |
| Argo CD URL | `https://argo.ghilbut.com/cd` |

private Gateway와 Argo CD VirtualService를 적용한다. `https://argo.ghilbut.com/cd`의 HTTP 응답과 TLS certificate를 확인한다.

```shell
kubectl --context cpa -n argo patch application argo \
  --type=merge \
  --patch '{"operation":{"sync":{"prune":true}}}'
kubectl --context cpa -n argo wait \
  --for=jsonpath='{.status.operationState.phase}'=Succeeded \
  application/argo \
  --timeout=20m
curl --fail --silent --show-error --output /dev/null \
  --write-out '%{http_code}\n' \
  https://argo.ghilbut.com/cd
```
