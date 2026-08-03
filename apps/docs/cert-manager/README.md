---
type: guide
area: apps
application: cert-manager
---

# cert-manager

CPA cluster에서 `ghilbut.com`, `ghilbut.net` DNS-01 challenge로 Istio 공용 gateway의 TLS Secret을 관리한다. `istio-gateways` namespace의 `cert-manager-dns01` ServiceAccount는 `platform-cpa-cert-manager` IAM 역할만 사용할 수 있다. Issuer와 Certificate는 `istio-gateways`에 한정한다.

## 연결

- [Argo CD Application](../../argo-apps/cert-manager.yaml)
- [cert-manager manifest 디렉터리](../../argo-apps/cert-manager/)
- [cert-manager OpenTofu module](../../tofu/modules/cert-manager/)
- [K3s ServiceAccount OIDC RUNBOOK](../../../k3s/RUNBOOK.md#d-serviceaccount-oidc와-aws-iam-federation)
