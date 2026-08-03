---
title: IAM Identity Center
---

# IAM Identity Center

`tofu/`는 IAM Identity Center permission set과 AWS 계정 할당을 관리한다. 기존 `tofu`
permission set은 새 역할별 permission set의 로그인을 검증할 때까지 유지한다.

| Permission set | 대상 계정 | Principal | 책임 |
|---|---|---|---|
| `foundation-management` | management | `DevOps` 그룹 | Organizations, 계정, 결제, IAM Identity Center 관리 |
| `platform-operator` | platform | `ghilbut` 사용자 | 플랫폼 워크로드 인프라 관리 |
| `ultary-domains-operator` | ultary-domains | `ghilbut` 사용자 | 도메인 등록과 Route 53 DNS 관리 |

`platform-operator`는 플랫폼 리소스와 IAM 역할을 관리할 수 있지만, inline deny policy로
Organizations, Billing, Account Management, IAM Identity Center 관리를 명시적으로 거부한다.

## CLI profile migration

새 permission set을 적용한 뒤 기존 `tofu` profile을 유지한 상태에서 검증용 profile로 로그인을
확인한다. 세 검증용 profile이 정상 동작하는 것을 확인한 후에만 기존 profile의 role name을
교체한다.

```sh
aws configure set sso_session ghilbut --profile ghilbut-foundation-management
aws configure set sso_account_id 384959722788 --profile ghilbut-foundation-management
aws configure set sso_role_name foundation-management --profile ghilbut-foundation-management
aws configure set region us-east-1 --profile ghilbut-foundation-management

aws configure set sso_session ghilbut --profile ghilbut-platform-operator
aws configure set sso_account_id 869061964712 --profile ghilbut-platform-operator
aws configure set sso_role_name platform-operator --profile ghilbut-platform-operator
aws configure set region us-east-1 --profile ghilbut-platform-operator

aws configure set sso_session ghilbut --profile ultary-domains-operator
aws configure set sso_account_id 971119963968 --profile ultary-domains-operator
aws configure set sso_role_name ultary-domains-operator --profile ultary-domains-operator
aws configure set region us-east-1 --profile ultary-domains-operator

aws sso login --profile ghilbut-foundation-management
aws sts get-caller-identity --profile ghilbut-foundation-management
aws sso login --profile ghilbut-platform-operator
aws sts get-caller-identity --profile ghilbut-platform-operator
aws sso login --profile ultary-domains-operator
aws sts get-caller-identity --profile ultary-domains-operator
```

이 단계는 기존 `tofu` permission set을 삭제하지 않는다. 검증이 완료되면 다음 변경에서
기존 permission set과 기존 할당을 제거한다.
