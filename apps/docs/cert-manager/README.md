---
type: guide
area: apps
application: cert-manager
---

# cert-manager

CPA cluster에서 `ghilbut.com`, `ghilbut.net` DNS-01 challenge로 Istio gateway의 TLS Secret을 관리한다. `cert-manager/cert-manager` ServiceAccount는 `platform-cpa-cert-manager` IAM 역할만 사용한다. ClusterIssuer `aws-route53`은 `istio-gateways/ingress-https` Certificate의 `id.ghilbut.com`, `argo.ghilbut.com`, `vault.ghilbut.com` TLS Secret을 발급하고 갱신한다.

## 연결

- [Argo CD Application](../../argo-apps/cert-manager.yaml)
- [cert-manager manifest 디렉터리](../../argo-apps/cert-manager/)
- [cert-manager OpenTofu module](../../tofu/modules/cert-manager/)
- [[k3s/RUNBOOK#D. ServiceAccount OIDC와 AWS IAM federation|K3s ServiceAccount OIDC RUNBOOK]]
