---
title: IAM Identity Center
---

# IAM Identity Center

`tofu/`는 IAM Identity Center permission set과 AWS 계정 할당을 관리한다. 기존 `tofu`,
`platform-operator`, `ultary-domains-operator` permission set은 대체 권한 세트의 로그인을
검증할 때까지만 유지한다.

| Permission set | 대상 계정 | Principal | 책임 |
|---|---|---|---|
| `foundation-management` | management | `DevOps` 그룹 | Organizations, 계정, 결제, IAM Identity Center 관리 |
| `ManagementTofuApply` | management | `DevOps` 그룹 | Foundation 계정·Identity OpenTofu 적용 |
| `TofuApply` | platform | `DevOps` 그룹 | Platform 워크로드 OpenTofu 적용 |
| `UltaryDomainsTofuApply` | ultary-domains | `DevOps` 그룹 | Ultary 도메인과 Route 53 OpenTofu 적용 |

`TofuApply`는 플랫폼 리소스와 IAM 역할을 관리할 수 있지만, inline deny policy로
Organizations, Billing, Account Management, IAM Identity Center 관리를 명시적으로 거부한다.

## CLI profile migration

새 permission set을 적용한 뒤 기존 profile을 유지한 상태에서 검증용 profile로 로그인을
확인한다. 세 검증용 profile이 정상 동작하는 것을 확인한 후에만 기존 permission set과 기존
할당을 제거한다.

```sh
aws configure set sso_session ghilbut --profile ghilbut-management-tofu-apply
aws configure set sso_account_id 384959722788 --profile ghilbut-management-tofu-apply
aws configure set sso_role_name ManagementTofuApply --profile ghilbut-management-tofu-apply
aws configure set region us-east-1 --profile ghilbut-management-tofu-apply

aws configure set sso_session ghilbut --profile ghilbut-tofu-apply
aws configure set sso_account_id 869061964712 --profile ghilbut-tofu-apply
aws configure set sso_role_name TofuApply --profile ghilbut-tofu-apply
aws configure set region us-east-1 --profile ghilbut-tofu-apply

aws configure set sso_session ghilbut --profile ghilbut-ultary-domains-tofu-apply
aws configure set sso_account_id 971119963968 --profile ghilbut-ultary-domains-tofu-apply
aws configure set sso_role_name UltaryDomainsTofuApply --profile ghilbut-ultary-domains-tofu-apply
aws configure set region us-east-1 --profile ghilbut-ultary-domains-tofu-apply

aws sso login --profile ghilbut-management-tofu-apply
aws sts get-caller-identity --profile ghilbut-management-tofu-apply
aws sso login --profile ghilbut-tofu-apply
aws sts get-caller-identity --profile ghilbut-tofu-apply
aws sso login --profile ghilbut-ultary-domains-tofu-apply
aws sts get-caller-identity --profile ghilbut-ultary-domains-tofu-apply
```

이 단계는 기존 permission set을 삭제하지 않는다. 검증이 완료되면 다음 변경에서 기존
permission set과 기존 할당을 제거한다.
