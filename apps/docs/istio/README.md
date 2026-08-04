---
type: guide
area: apps
application: istio
---

# Istio

CPA cluster의 traffic management control plane과 ingress gateway를 관리한다. [Cilium](../../argo-apps/cilium.yaml), [Istio system](../../argo-apps/istio-system.yaml), [Istio gateways](../../argo-apps/istio-gateways.yaml)는 독립 Argo CD Application이다. 설치 시에는 이 순서로 각 Application이 Healthy인지 확인하며 동기화한다. namespace 전체에 sidecar를 기본 주입하지 않으며, ingress gateway만 명시적으로 주입한다. `public` Gateway는 `id.ghilbut.com`을 공용 DNS에 노출한다. `private` Gateway는 `id.ghilbut.com`, `argo.ghilbut.com`, `vault.ghilbut.com`을 LAN DNS에 노출한다. `ingress-https` Certificate는 세 hostname의 TLS Secret을 관리한다.

## 연결

- [Istio system manifest 디렉터리](../../argo-apps/istio-system/)
- [Istio gateways manifest 디렉터리](../../argo-apps/istio-gateways/)
