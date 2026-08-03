---
type: runbook
area: apps
cluster: cpa
---

# Applications 설치

CPA cluster에 Argo CD Application을 설치하고 `https://argo.ghilbut.com/cd`를 제공한다.

## A. 공통 도메인 값

| 항목 | 값 |
| --- | --- |
| DNS zones | `ghilbut.com`, `ghilbut.net` |

## B. 사전 확인

[[k3s/runbooks/CPA|CPA K3s 재설치 Runbook]]가 `cpa` context, K3s, Cilium, Argo CD 기본 설치와 `openebs` volume group을 준비한 뒤에 이 Runbook을 실행한다.

```shell
kubectl --context cpa get nodes
kubectl --context cpa -n argo get deployment,statefulset,pod
kubectl --context cpa -n argo get secret argocd-initial-admin-secret
```

## C. 설치 순서

### 1. Argo CD Application bootstrap

[Argo CD Application specification](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/)을 참고한다.

`argo-apps` Application을 적용한다. 이 명령 뒤에 `argocd app sync` 또는 Application의 `operation.sync`를 실행하지 않는다. `argo-apps`의 automated sync는 child Application 리소스를 생성한다. child Application은 명시적 sync 전까지 workload를 생성하지 않는다.

```shell
kubectl --context cpa apply -f apps/argo-apps/argo-apps.yaml
kubectl --context cpa -n argo get application argo-apps
kubectl --context cpa -n argo get applications
```

### 2. Istio system과 Argo CD sidecar

[Istio sidecar injection](https://istio.io/latest/docs/setup/additional-setup/sidecar-injection/)을 참고한다.

`istio-system`을 sync한다. `argo` namespace에 sidecar injection을 설정하고 Argo CD Deployment와 StatefulSet을 재배포한다. 각 Argo CD Pod에 `istio-proxy` container가 있어야 한다.

```shell
kubectl --context cpa -n argo patch application istio-system \
  --type=merge \
  --patch '{"operation":{"sync":{"prune":true}}}'
kubectl --context cpa -n argo wait \
  --for=jsonpath='{.status.operationState.phase}'=Succeeded \
  application/istio-system \
  --timeout=20m
kubectl --context cpa label namespace argo istio-injection=enabled --overwrite
kubectl --context cpa -n argo rollout restart deployment --all
kubectl --context cpa -n argo rollout restart statefulset --all
kubectl --context cpa -n argo rollout status deployment --all --timeout=10m
kubectl --context cpa -n argo rollout status statefulset --all --timeout=10m
kubectl --context cpa -n argo get pods \
  -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].name}{"\n"}{end}'
```

### 3. Istio ingress와 egress gateway

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

### 4. OpenEBS LVM

[OpenEBS 설치](https://openebs.io/docs/main/quickstart-guide/installation)를 참고한다.

#### 설치 값

| 항목 | 값 |
| --- | --- |
| LVM volume group | `openebs` |
| StorageClass | `openebs-lvm` |

`ebs`를 sync한다. OpenEBS LVM controller와 node Pod, `openebs` volume group을 사용하는 `openebs-lvm` StorageClass를 확인한다.

```shell
kubectl --context cpa -n argo patch application ebs \
  --type=merge \
  --patch '{"operation":{"sync":{"prune":true}}}'
kubectl --context cpa -n argo wait \
  --for=jsonpath='{.status.operationState.phase}'=Succeeded \
  application/ebs \
  --timeout=20m
kubectl --context cpa -n ebs get pods
kubectl --context cpa get storageclass openebs-lvm
```

### 5. CoreDNS

`coredns`를 sync한다. CoreDNS가 Ready인지 확인한다.

#### 설치 값

| 항목 | 값 |
| --- | --- |
| CoreDNS listener | `192.168.254.4:53` |

#### etcd

[CoreDNS etcd plugin](https://coredns.io/plugins/etcd/)을 참고한다. CoreDNS 전용 etcd PersistentVolumeClaim은 `openebs-lvm` StorageClass를 사용한다. CoreDNS와 etcd가 Ready인 뒤 `ghilbut.com`과 `ghilbut.net` zone을 조회한다.

```shell
kubectl --context cpa -n argo patch application coredns \
  --type=merge \
  --patch '{"operation":{"sync":{"prune":true}}}'
kubectl --context cpa -n argo wait \
  --for=jsonpath='{.status.operationState.phase}'=Succeeded \
  application/coredns \
  --timeout=20m
kubectl --context cpa -n coredns get pvc,pod,service
dig @192.168.254.4 ghilbut.com SOA
dig @192.168.254.4 ghilbut.net SOA
```

### 6. external-dns

[ExternalDNS Istio source](https://kubernetes-sigs.github.io/external-dns/latest/docs/sources/istio/)와 [ExternalDNS target annotation](https://kubernetes-sigs.github.io/external-dns/latest/docs/annotations/annotations/#external-dnsalpha-kubernetes-io-target)을 참고한다.

#### 설치 값

| 항목 | 값 |
| --- | --- |
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

### 7. cert-manager

[cert-manager Route 53 DNS-01](https://cert-manager.io/docs/configuration/acme/dns01/route53/)을 참고한다.

#### 설치 값

| 항목 | 값 |
| --- | --- |
| Certificate DNS name | `argo.ghilbut.com` |

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
