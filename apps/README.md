---
type: guide
area: apps
---

# Applications

`apps/`는 CPA Kubernetes cluster에서 실행되는 애플리케이션의 진입점이다. Argo CD bootstrap은 [argo.yaml](argo.yaml)에서 시작하며, AWS 인프라는 [OpenTofu](tofu/README.md)에서 관리한다.

## 애플리케이션

| 애플리케이션 | 배포 또는 문서 |
| --- | --- |
| Argo CD | [Application](argo-apps/argo.yaml) · [app-of-apps](argo-apps/argo-apps.yaml) |
| Cilium | [Application](argo-apps/cilium.yaml) |
| OpenEBS | [Application](argo-apps/ebs.yaml) |
| cert-manager | [Application](argo-apps/cert-manager.yaml) |
| external-dns | [Application](argo-apps/external-dns.yaml) |
| Istio | [Applications](argo-apps/istio.yaml) |
| Keycloak | [Application](argo-apps/keycloak.yaml) |
| Vault | [Application](argo-apps/vault.yaml) · [RUNBOOK](argo-apps/vault/RUNBOOK.md) · [PLAYBOOK](argo-apps/vault/PLAYBOOK.md) |
