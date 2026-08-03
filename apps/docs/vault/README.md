---
type: guide
area: apps
application: vault
---

# Vault

CPA cluster의 비밀 관리 애플리케이션이다.

`platform-vault` IAM 역할은 [[k3s/RUNBOOK#D. ServiceAccount OIDC와 AWS IAM federation|K3s ServiceAccount OIDC RUNBOOK]]의 CPA IAM OIDC provider를 조회해 ServiceAccount token federation을 사용한다.

## 연결

- [Argo CD Application](../../argo-apps/vault.yaml)
- [Applications OpenTofu](../../tofu/)
- [[k3s/RUNBOOK#D. ServiceAccount OIDC와 AWS IAM federation|K3s ServiceAccount OIDC RUNBOOK]]
