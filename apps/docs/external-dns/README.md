---
type: guide
area: apps
application: external-dns
---

# external-dns

CPA Istio `public` Gateway의 `id.ghilbut.com`, `vault.ghilbut.com` CNAME과 TXT ownership record를 Route 53에서 관리한다. `external-dns` ServiceAccount는 다수 cluster가 공유하는 `platform-external-dns` IAM 역할을 사용한다. role의 OIDC trust는 cluster별 ServiceAccount subject로 제한하고, 등록된 cluster는 선언된 Route 53 record 범위를 공유한다.

## 연결

- [Argo CD Application](../../argo-apps/external-dns.yaml)
- [external-dns manifest 디렉터리](../../argo-apps/external-dns/)
- [external-dns OpenTofu module](../../tofu/modules/external-dns/)
- [Istio gateways manifest 디렉터리](../../argo-apps/istio-gateways/)
- [K3s OIDC](../../../k3s/OIDC.md)
