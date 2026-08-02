---
type: guide
area: apps
application: vault
---

# Vault

Vault는 CPA cluster에서 Integrated Raft storage와 AWS KMS auto-unseal을 사용하는 비밀 관리 애플리케이션이다. AWS KMS 접근은 CPA ServiceAccount OIDC federation의 `platform-vault` 역할로 제한한다.

## 연결

| 항목 | 위치 |
| --- | --- |
| 문서 규칙 | [Applications Documents RULEBOOK](../RULEBOOK.md) |
| Argo CD Application | [Vault Application](../../argo-apps/vault.yaml) |
| namespace manifest | [Vault namespace](../../argo-apps/vault/namespace.yaml) |
| AWS KMS seal과 IAM 역할 | [Applications OpenTofu](../../tofu/README.md#vault-구성) |
| CPA OIDC issuer | [K3s OIDC](../../../k3s/OIDC.md) |
| 설치와 초기화 | [RUNBOOK](RUNBOOK.md) |
| 복구와 workload 이전 | [PLAYBOOK](PLAYBOOK.md) |
