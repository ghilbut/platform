---
title: Remove Vault and split application IAM federation
type: runbook
area: domains
tags:
  - aws
  - iam
  - kubernetes
  - opentofu
---

# Remove Vault and split application IAM federation

이 Runbook은 Vault를 삭제하고 CPA IAM federation을 Domains와 Platform으로 분리한다. Vault
데이터와 AWS KMS seal은 이전하지 않는다.

## 삭제 대상

| 위치 | 리소스 |
|---|---|
| CPA | Vault Argo CD Application, workload, PVC, PV, ServiceAccount, namespace |
| Domains AWS | `platform-vault` 역할과 정책, `alias/platform-vault`, Vault KMS key |
| Git | Vault manifest와 문서, `vault.ghilbut.com` ingress와 certificate 설정 |

KMS key 삭제는 30일 대기 상태로 전환한다. `PendingDeletion` 상태와 삭제 날짜를 확인한다.

## 1. Domains 실행 역할 Bootstrap

Bootstrap commit은 Domains provider의 `assume_role` block을 제거하고
`allowed_account_ids = ["869061964712"]`를 유지한다. `tofu-apply-domains` 정책에는 다음 권한만
추가한다.

- `domains-cpa-cert-manager`, `domains-cpa-external-dns` 역할과 inline policy 관리
- `oidc.k3s.ghilbut.com/cpa` IAM OIDC provider 관리

```sh
AWS_PROFILE=ghilbut-tofu-apply-for-workloads-domains \
  tofu -chdir=domains/tofu plan -out=/tmp/issue-102-domains-bootstrap.tfplan
AWS_PROFILE=ghilbut-tofu-apply-for-workloads-domains \
  tofu -chdir=domains/tofu apply /tmp/issue-102-domains-bootstrap.tfplan
```

적용 뒤 provider의 `assume_role` block을 복원한다.

## 2. 새 federation 생성

1. Platform workload state에 CPA IAM OIDC provider를 만든다. 이름 prefix는 `platform`이다.
2. Domains state에 `domains-cpa-cert-manager`, `domains-cpa-external-dns` 역할을 만든다.
3. cert-manager와 external-dns manifest를 최종 Domains 역할 ARN으로 바꾼다.
4. CPA에서 두 workload가 새 역할을 수임하는지 확인한다.

## 3. Vault 삭제

CPA Kubernetes API가 연결되는 상태에서 다음 순서로 삭제한다.

1. Vault Argo CD Application과 Helm workload를 삭제한다.
2. `data-vault-0` PVC와 연결된 PV를 삭제한다.
3. `vault` namespace가 비어 있는지 확인하고 namespace를 삭제한다.
4. Apps OpenTofu 구성에서 Vault module 선언과 resource block을 완전히 제거한다.
5. `tofu destroy -target`은 사용하지 않는다. KMS key의 `prevent_destroy`는 resource block이 남아
   있으면 삭제 계획을 차단한다.
6. Apps OpenTofu plan에서 Vault 역할, 역할 정책, KMS alias, KMS key만 삭제하는지 확인한다.
7. saved plan을 적용한다.
8. KMS key가 `PendingDeletion`이고 alias와 IAM 역할이 없는지 확인한다.

## 4. 기존 federation 정리

1. K3s state에서 Domains CPA IAM OIDC provider를 `destroy = false`로 제거한다.
2. 같은 provider ARN을 Domains state로 import한다.
3. Apps state의 기존 `platform-cpa-cert-manager`와 `platform-cpa-external-dns` 역할을 삭제한다.
4. Apps state에 관리 리소스가 없고 Domains, Platform workload, K3s root가 무변경인지 확인한다.
