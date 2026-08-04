---
type: guide
area: apps
application: external-dns
---

# external-dns

CPA Istio `public` Gateway의 `id.ghilbut.com`, `vault.ghilbut.com` CNAME과 TXT ownership record를 Route 53에서 관리한다. `external-dns` ServiceAccount는 `platform-cpa-external-dns` IAM 역할만 사용할 수 있다.

## 연결

- [Argo CD Application](../../argo-apps/external-dns.yaml)
- [external-dns manifest 디렉터리](../../argo-apps/external-dns/)
- [external-dns OpenTofu module](../../tofu/modules/external-dns/)
- [Istio gateways manifest 디렉터리](../../argo-apps/istio-gateways/)
- [[k3s/RUNBOOK#D. ServiceAccount OIDC와 AWS IAM federation|K3s ServiceAccount OIDC RUNBOOK]]
