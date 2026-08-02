---
type: guide
area: apps
---

# Applications

`apps/`는 CPA Kubernetes cluster에서 실행되는 플랫폼 애플리케이션의 배포 manifest와 AWS 인프라를 관리한다.

## 구성

| 경로 | 책임 |
| --- | --- |
| [argo.yaml](argo.yaml) | Argo CD bootstrap Application |
| [argo-apps/](argo-apps/) | Argo CD Application과 Kubernetes manifest |
| [tofu/](tofu/README.md) | 애플리케이션별 AWS 인프라와 IAM federation |

## Vault 문서 추적

| 목적 | 문서 또는 manifest |
| --- | --- |
| Argo CD 배포 정의 | [Vault Application](argo-apps/vault.yaml) |
| AWS KMS seal과 IAM federation | [Applications OpenTofu](tofu/README.md#vault-구성) |
| 설치, 수동 초기화, 일상 확인, 수동 snapshot | [Vault 운영 RUNBOOK](argo-apps/vault/RUNBOOK.md) |
| 데이터 손실 복구와 다른 workload 이전 | [Vault 복구 PLAYBOOK](argo-apps/vault/PLAYBOOK.md) |
| CPA ServiceAccount issuer와 IAM OIDC provider 경계 | [K3s OIDC](../k3s/OIDC.md) |

Vault 설치는 RUNBOOK을 시작점으로 사용한다. 데이터 손실이나 workload 이전은 PLAYBOOK만 사용한다. 자동 backup workload는 별도 PR에서 정의한다.
