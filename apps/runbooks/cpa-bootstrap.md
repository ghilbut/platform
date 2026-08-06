---
type: run
area: apps
cluster: cpa
---

# CPA bootstrap

CPA Argo CD가 검증된 Application 집합을 관리하도록 만든다. 이 문서는 [[k3s/runbooks/CPA|CPA K3s 기반 준비]]가 끝난 뒤 실행한다.

## A. Bootstrap revision

| 항목 | 값 |
| --- | --- |
| tag | `cpa-bootstrap-v1` |
| commit SHA | `315bea2f88984c2458ca63c916e3e664a54a49bd` |

tag는 bootstrap 기준점의 이름이다. commit SHA는 bootstrap 대상의 불변 식별자다. 둘이 같은 commit을 가리킬 때만 계속한다.

```shell
export BOOTSTRAP_TAG='cpa-bootstrap-v1'
export BOOTSTRAP_REVISION='315bea2f88984c2458ca63c916e3e664a54a49bd'

git fetch origin "refs/tags/${BOOTSTRAP_TAG}:refs/tags/${BOOTSTRAP_TAG}"
test "$(git rev-list -n 1 "$BOOTSTRAP_TAG")" = "$BOOTSTRAP_REVISION"
git show --no-patch --format='%H %D' "$BOOTSTRAP_REVISION"
```

## B. CPA Argo CD

[Argo CD Helm 설치](https://argo-cd.readthedocs.io/en/stable/operator-manual/installation/#helm)를 따라 CPA에 Argo CD를 설치한다. 이 설치는 `argo-apps`를 적용하기 위한 최소 bootstrap이다.

```shell
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
    admin.enabled: true
    application.resourceTrackingMethod: annotation+label
    users.anonymous.enabled: true
  params:
    server.insecure: true
    server.basehref: /cd
    server.rootpath: /cd
  rbac:
    policy.default: role:admin
  secret:
    createSecret: false
dex:
  enabled: false
notifications:
  enabled: false
YAML
kubectl --context cpa -n argo wait \
  --for=condition=Available deployment/cd-server \
  --timeout=10m
```

## C. Immutable `argo-apps`

`argo-apps`는 child Application만 생성한다. 이 단계에서 `argocd app sync argo-apps`와 `operation.sync`를 실행하지 않는다.

```shell
test "$(git show "$BOOTSTRAP_REVISION:apps/argo-apps/argo-apps.yaml" \
  | grep -c '^    targetRevision: main$')" -eq 1

git show "$BOOTSTRAP_REVISION:apps/argo-apps/argo-apps.yaml" \
  | sed "s#^    targetRevision: main\$#    targetRevision: $BOOTSTRAP_REVISION#" \
  | kubectl --context cpa apply -f -

kubectl --context cpa -n argo get application argo-apps \
  -o jsonpath='{.spec.source.targetRevision}{"\n"}' \
  | grep -Fx "$BOOTSTRAP_REVISION"
kubectl --context cpa -n argo wait \
  --for=jsonpath='{.status.sync.revision}'="$BOOTSTRAP_REVISION" \
  application/argo-apps \
  --timeout=10m
kubectl --context cpa -n argo get applications
```

## D. 기반 Application

Argo CD CLI는 CPA Argo CD에 port-forward로 연결한다. 각 Application은 sync 뒤 `wait --sync --health`로 완료를 확인한다.

```shell
sync_and_wait() {
  local application="$1"

  argocd app sync "$application" \
    --kube-context cpa \
    --port-forward \
    --port-forward-namespace argo \
    --plaintext \
    --timeout 1200
  argocd app wait "$application" \
    --sync \
    --health \
    --kube-context cpa \
    --port-forward \
    --port-forward-namespace argo \
    --plaintext \
    --timeout 1200
}
```

### 1. Istio CNI와 Istio system

Istio CNI는 Cilium 뒤에서 chained CNI plugin으로 실행된다. `istio-cni`를 먼저 완료한 뒤 `istio-system`을 완료한다.

```shell
sync_and_wait istio-cni
kubectl --context cpa -n kube-system wait \
  --for=condition=Ready daemonset/istio-cni-node \
  --timeout=10m

sync_and_wait istio-system
kubectl --context cpa -n istio-system wait \
  --for=condition=Available deployment/istiod \
  --timeout=10m

argo_pods="$(kubectl --context cpa -n argo get pod -o name)"
kubectl --context cpa -n argo rollout restart deployment,statefulset
printf '%s\n' "$argo_pods" \
  | xargs -r -n 1 kubectl --context cpa -n argo wait \
    --for=delete \
    --timeout=10m
kubectl --context cpa -n argo wait \
  --for=condition=Ready pod \
  --all \
  --timeout=10m
```

### 2. OpenEBS LVM과 CoreDNS

```shell
sync_and_wait ebs
kubectl --context cpa get storageclass openebs-lvm \
  -o jsonpath='{.provisioner}{"\t"}{.parameters.volgroup}{"\n"}'

sync_and_wait coredns
kubectl --context cpa -n coredns wait \
  --for=jsonpath='{.status.phase}'=Bound \
  persistentvolumeclaim/data-etcd-0 \
  --timeout=10m
dig @192.168.254.4 ghilbut.com SOA
dig @192.168.254.4 ghilbut.net SOA
```

CoreDNS가 Ready이면 ASUS Router의 `LAN > DHCP Server > DNS Server`를 `192.168.254.4`로 설정한다. `Advertise router’s IP in addition to user specified DNS`는 `No`로 설정한다.

### 3. external-dns와 cert-manager

Route 53 권한을 적용한 뒤 각 Application을 완료한다.

```shell
AWS_PROFILE=ghilbut-tofu-apply-for-workloads AWS_SDK_LOAD_CONFIG=1 \
  tofu -chdir=apps/tofu init -reconfigure \
    -backend-config=tofu-state-apply.tfbackend
AWS_PROFILE=ghilbut-tofu-apply-for-workloads AWS_SDK_LOAD_CONFIG=1 \
  tofu -chdir=apps/tofu apply

sync_and_wait external-dns
kubectl --context cpa -n external-dns get deployment,pod,serviceaccount

sync_and_wait cert-manager
kubectl --context cpa -n cert-manager get deployment,pod
```

### 4. Istio Gateways와 Argo route

`istio-gateways`를 완료한 뒤 private Gateway certificate를 확인한다. `argo` 전체는 sync하지 않는다. `routes.yml`의 VirtualService만 sync하고 operation 완료를 기다린다.

```shell
sync_and_wait istio-gateways
kubectl --context cpa -n istio-gateways wait \
  --for=condition=Ready certificate/ingress-https \
  --timeout=10m

argocd app sync argo \
  --resource networking.istio.io:VirtualService:argo/argo \
  --kube-context cpa \
  --port-forward \
  --port-forward-namespace argo \
  --plaintext \
  --timeout 1200
argocd app wait argo \
  --operation \
  --resource networking.istio.io:VirtualService:argo/argo \
  --kube-context cpa \
  --port-forward \
  --port-forward-namespace argo \
  --plaintext \
  --timeout 1200
curl --fail --silent --show-error --output /dev/null \
  --location \
  --write-out '%{http_code}\n' \
  https://argo.ghilbut.com/cd
```

## E. `main` handoff

기반 Application이 완료된 뒤 `argo-apps`를 `main`으로 전환한다. 이 변경은 child Application 선언을 갱신한다. child workload를 전체 sync하지 않는다.

```shell
kubectl --context cpa -n argo patch application argo-apps \
  --type=merge \
  --patch '{"spec":{"source":{"targetRevision":"main"}}}'
main_revision="$(git ls-remote origin refs/heads/main | awk '{print $1}')"
test -n "$main_revision"
kubectl --context cpa -n argo get application argo-apps \
  -o jsonpath='{.spec.source.targetRevision}{"\n"}' \
  | grep -Fx main
kubectl --context cpa -n argo wait \
  --for=jsonpath='{.status.sync.revision}'="$main_revision" \
  application/argo-apps \
  --timeout=10m
kubectl --context cpa -n argo get applications
```

이후 Application 추가와 변경은 `apps/argo-apps/` YAML로 관리한다. bootstrap tag와 commit SHA는 검증된 기반 구성이 바뀔 때만 함께 갱신한다.
