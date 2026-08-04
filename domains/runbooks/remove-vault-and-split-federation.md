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

## 현재 CPA 상태

CPA에는 K3s 서비스가 없다. K3s server database 크기는 4 KiB이고 OpenEBS volume group의
logical volume 수는 0개다. 삭제할 Kubernetes workload, PVC, PV가 없다.

```sh
ssh cpa systemctl status k3s
ssh cpa sudo du -sh /var/lib/rancher/k3s/server/db
ssh cpa sudo vgs openebs -o vg_name,lv_count,vg_size,vg_free
```

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

1. 실행 역할 정책에 변경이 남으면 provider의 `assume_role` block을 임시로 제거한다.
2. Domains workload profile로 실행 역할 정책만 계획한다.

   ```sh
   AWS_PROFILE=ghilbut-tofu-apply-for-workloads-domains \
     tofu -chdir=domains/tofu plan \
       -target='module.tofu_execution_role.aws_iam_role_policy.this[0]' \
       -out=/tmp/issue-102-domains-policy-narrowing.tfplan
   ```

3. 계획이 실행 역할 정책의 `0 add, 1 change, 0 destroy`인지 확인하고 적용한다.

   ```sh
   AWS_PROFILE=ghilbut-tofu-apply-for-workloads-domains \
     tofu -chdir=domains/tofu apply /tmp/issue-102-domains-policy-narrowing.tfplan
   ```

4. provider의 `assume_role` block을 복원한다.
5. Platform state에 CPA IAM OIDC provider를 만든다.
6. Domains 계획이 역할 2개와 inline policy 2개의 `4 add, 0 change, 0 destroy`인지 확인한다.
7. Domains state에 `domains-cpa-cert-manager`, `domains-cpa-external-dns` 역할을 만든다.
8. cert-manager와 external-dns manifest를 최종 Domains 역할 ARN으로 바꾼다.
9. K3s를 설치한 뒤 CPA에서 두 workload가 새 역할을 수임하는지 확인한다.

## 3. Vault 삭제

CPA에 Kubernetes 리소스와 OpenEBS logical volume이 없으므로 AWS와 Git 리소스만 삭제한다.

1. Apps OpenTofu 구성에서 Vault, cert-manager, external-dns module을 제거한다.
2. Apps saved plan이 `0 add, 0 change, 8 destroy`인지 확인한다.
3. saved plan을 적용한다.
4. Apps state의 관리 리소스가 0개인지 확인한다.
5. KMS key 상태가 `PendingDeletion`이고 삭제 날짜가 `2026-09-04T01:16:50.578000+09:00`인지
   확인한다.
6. `alias/platform-vault`, `platform-vault`, `platform-cpa-cert-manager`,
   `platform-cpa-external-dns`가 없는지 확인한다.
7. Vault manifest와 문서를 삭제한다.
8. ingress, certificate, external-dns 설정에서 `vault.ghilbut.com`을 제거한다.

```sh
AWS_PROFILE=ghilbut-tofu-apply-for-workloads-domains \
  tofu -chdir=apps/tofu state list
AWS_PROFILE=ghilbut-tofu-apply-for-workloads-domains \
  aws kms describe-key --key-id 6ebc75ad-c084-4c1a-842e-b45482e5e668
AWS_PROFILE=ghilbut-tofu-apply-for-workloads-domains \
  aws kms list-aliases --query "Aliases[?AliasName=='alias/platform-vault']"
```

## 4. 기존 federation 정리

K3s Kubernetes API가 없으므로 전체 plan 대신 state에서 OIDC provider 한 개만 해제한다. S3 state의
해제 전 version ID는 `nvARpQasp9Q_o1aKPTM08gUaGpCi3VKD`다.

```sh
AWS_SDK_LOAD_CONFIG=1 AWS_PROFILE=ghilbut-tofu-apply-for-workloads-domains \
  tofu -chdir=k3s/tofu state rm -dry-run 'aws_iam_openid_connect_provider.cpa'
AWS_SDK_LOAD_CONFIG=1 AWS_PROFILE=ghilbut-tofu-apply-for-workloads-domains \
  tofu -chdir=k3s/tofu state rm 'aws_iam_openid_connect_provider.cpa'
```

Domains의 import block으로 같은 ARN을 가져온다. 계획과 적용 결과는 `1 import, 0 add, 0 change,
0 destroy`여야 한다.

```sh
AWS_PROFILE=ghilbut-tofu-apply-for-domains \
  tofu -chdir=domains/tofu plan -out=/tmp/issue-102-domains-oidc-import.tfplan
AWS_PROFILE=ghilbut-tofu-apply-for-domains \
  tofu -chdir=domains/tofu apply /tmp/issue-102-domains-oidc-import.tfplan
```

## 5. 완료 확인

- Domains state는 CPA IAM OIDC provider와 `domains-cpa-cert-manager`,
  `domains-cpa-external-dns` 역할을 관리한다.
- Platform state는 Platform 계정의 CPA IAM OIDC provider를 관리한다.
- K3s state는 OIDC discovery object와 JWKS object만 관리한다.
- Apps state의 관리 리소스는 0개다.
- Domains, Platform, Apps 계획에는 변경 사항이 없다.
- KMS key는 `PendingDeletion` 상태다.
- Vault KMS alias와 기존 IAM 역할은 없다.
- Domains Route 53 hosted zone에는 Vault record가 없다.
