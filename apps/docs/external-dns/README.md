---
type: guide
area: apps
application: external-dns
---

# external-dns

CPA Istio `public` Gateway의 `id.ghilbut.com` CNAME과 TXT ownership record를 Route 53에서 관리한다. `private` Gateway의 `id.ghilbut.com`, `argo.ghilbut.com`, `vault.ghilbut.com` A record와 TXT ownership record는 CoreDNS etcd backend에서 관리한다. public과 private Gateway의 `external-dns.alpha.kubernetes.io/target` annotation은 각각 `ghilbut.asuscomm.com`, `192.168.254.4`를 지정한다. external-dns ServiceAccount는 `platform-cpa-external-dns` IAM 역할만 사용할 수 있다.

## 연결

- [Argo CD Application](../../argo-apps/external-dns.yaml)
- [external-dns manifest 디렉터리](../../argo-apps/external-dns/)
- [external-dns OpenTofu module](../../tofu/modules/external-dns/)
- [Istio gateways manifest 디렉터리](../../argo-apps/istio-gateways/)
- [[k3s/RUNBOOK#D. ServiceAccount OIDC와 AWS IAM federation|K3s ServiceAccount OIDC RUNBOOK]]
