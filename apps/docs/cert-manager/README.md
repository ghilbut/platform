---
type: guide
area: apps
application: cert-manager
---

# cert-manager

CPA cluster에서 `ghilbut.com`, `ghilbut.net` DNS-01 challenge로 Istio 공용 gateway의 TLS Secret을 관리한다. `istio-gateways` namespace의 `cert-manager-dns01` ServiceAccount는 다수 cluster가 공유하는 `platform-cert-manager` IAM 역할을 사용한다. role의 OIDC trust는 cluster별 DNS-01 ServiceAccount subject로 제한하고, 등록된 cluster는 선언된 hosted zone 범위를 공유한다. Issuer와 Certificate는 `istio-gateways`에 한정한다.

## 연결

- [Argo CD Application](../../argo-apps/cert-manager.yaml)
- [cert-manager manifest 디렉터리](../../argo-apps/cert-manager/)
- [cert-manager OpenTofu module](../../tofu/modules/cert-manager/)
- [K3s OIDC](../../../k3s/OIDC.md)
