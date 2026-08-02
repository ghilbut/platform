---
type: guide
area: apps
application: istio
---

# Istio

CPA cluster의 traffic management control plane과 공용 ingress gateway를 관리한다. [Cilium](../../argo-apps/cilium.yaml), [Istio system](../../argo-apps/istio-system.yaml), [Istio gateways](../../argo-apps/istio-gateways.yaml)는 독립 Argo CD Application이다. 설치 시에는 이 순서로 각 Application이 Healthy인지 확인하며 동기화한다. namespace 전체에 sidecar를 기본 주입하지 않으며, ingress gateway만 명시적으로 주입한다. `public` Gateway는 `id.ghilbut.com`과 `vault.ghilbut.com`만 수용한다. 인증서, DNS record, 애플리케이션 route는 각각의 후속 애플리케이션 작업에서 관리한다.

## 연결

- [Istio system manifest 디렉터리](../../argo-apps/istio-system/)
- [Istio gateways manifest 디렉터리](../../argo-apps/istio-gateways/)
