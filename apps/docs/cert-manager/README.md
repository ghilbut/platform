---
type: guide
area: apps
application: cert-manager
---

# cert-manager

CPA cluster에서 `ghilbut.com`, `ghilbut.net` DNS-01 challenge로 Istio gateway의 TLS Secret을
관리한다. `cert-manager` namespace의 `cert-manager` ServiceAccount는
`domains-cpa-cert-manager` IAM 역할만 사용할 수 있다. ClusterIssuer는 `aws-route53`이고
Certificate는 `istio-gateways` namespace에 둔다.

## 연결

- [Argo CD Application](../../argo-apps/cert-manager.yaml)
- [cert-manager manifest 디렉터리](../../argo-apps/cert-manager/)
- [Domains cert-manager OpenTofu module](../../../domains/tofu/modules/cert-manager/)
- [[k3s/RUNBOOK#D. ServiceAccount OIDC와 AWS IAM federation|K3s ServiceAccount OIDC RUNBOOK]]
