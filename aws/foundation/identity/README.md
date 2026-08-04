---
title: IAM Identity Center
---

# IAM Identity Center

`tofu/`는 IAM Identity Center permission set과 AWS 계정 할당을 관리한다.

| Permission set | 대상 계정 | Principal | 책임 |
|---|---|---|---|
| `foundation-management` | management | `DevOps` 그룹 | Organizations, 계정, 결제, IAM Identity Center 관리 |
| `ManagementTofuApply` | management | `DevOps` 그룹 | Foundation 계정·Identity OpenTofu 적용 |
| `TofuApply` | platform | `DevOps` 그룹 | Platform 워크로드 OpenTofu 적용 |
| `UltaryDomainsTofuApply` | ultary-domains | `DevOps` 그룹 | Ultary 도메인과 Route 53 OpenTofu 적용 |

새 permission set은 기존 할당을 유지한 채 추가한다. provider 인증과 실행 역할 신뢰 정책을
전환한 뒤 기존 permission set을 제거한다.

| Permission set | 대상 계정 | Principal | 책임 |
|---|---|---|---|
| `TofuApplyForManagement` | management | `DevOps` 그룹 | Management 계정 OpenTofu 적용 |
| `TofuApplyForDomains` | platform | `DevOps` 그룹 | Domains 이전 전 Route 53 관리 |
| `TofuApplyForWorkloads` | platform | `DevOps` 그룹 | 현재 Platform 워크로드 OpenTofu 적용 |
| `TofuApplyForUltaryDomains` | ultary-domains | `DevOps` 그룹 | Ultary Domains Route 53 관리 |

`TofuApply`는 플랫폼 리소스와 IAM 역할을 관리할 수 있지만, inline deny policy로
Organizations, Billing, Account Management, IAM Identity Center 관리를 명시적으로 거부한다.

## OpenTofu 실행 역할

IAM Identity Center permission set은 사람 또는 CI의 최초 인증에만 사용한다. OpenTofu는
별도 IAM 실행 역할을 수임해 AWS 리소스를 관리한다. permission set 이름이 바뀌지 않아도
AWS가 생성하는 `AWSReservedSSO` 역할의 suffix는 바뀔 수 있으므로, 실행 역할의 신뢰 정책은
permission set 이름과 역할 경로를 조건으로 사용한다.

각 최초 인증 permission set은 표에 있는 실행 역할 한 개에만 `sts:AssumeRole`을 허용한다.
`TofuApplyForManagement`는 Foundation accounts·identity state와 lock file의 S3 접근도
가진다.

| 최초 인증 permission set | 실행 역할 | 관리 state |
|---|---|---|
| `TofuApplyForManagement` | `tofu-apply` | Foundation identity와 accounts |
| `TofuApplyForWorkloads` | `tofu-apply` | CDN |

## CLI profile migration

새 permission set은 기존 profile과 별도의 검증용 profile로 로그인한다. provider와 backend를
전환하기 전에는 기존 permission set과 profile을 제거하지 않는다.

```sh
aws configure set sso_session ghilbut --profile ghilbut-tofu-apply-for-management
aws configure set sso_account_id 384959722788 --profile ghilbut-tofu-apply-for-management
aws configure set sso_role_name TofuApplyForManagement --profile ghilbut-tofu-apply-for-management
aws configure set region us-east-1 --profile ghilbut-tofu-apply-for-management

aws configure set sso_session ghilbut --profile ghilbut-tofu-apply-for-domains
aws configure set sso_account_id 869061964712 --profile ghilbut-tofu-apply-for-domains
aws configure set sso_role_name TofuApplyForDomains --profile ghilbut-tofu-apply-for-domains
aws configure set region us-east-1 --profile ghilbut-tofu-apply-for-domains

aws configure set sso_session ghilbut --profile ghilbut-tofu-apply-for-workloads
aws configure set sso_account_id 869061964712 --profile ghilbut-tofu-apply-for-workloads
aws configure set sso_role_name TofuApplyForWorkloads --profile ghilbut-tofu-apply-for-workloads
aws configure set region us-east-1 --profile ghilbut-tofu-apply-for-workloads

aws configure set sso_session ghilbut --profile ghilbut-tofu-apply-for-ultary-domains
aws configure set sso_account_id 971119963968 --profile ghilbut-tofu-apply-for-ultary-domains
aws configure set sso_role_name TofuApplyForUltaryDomains --profile ghilbut-tofu-apply-for-ultary-domains
aws configure set region us-east-1 --profile ghilbut-tofu-apply-for-ultary-domains

aws sso login --profile ghilbut-tofu-apply-for-management
aws sts get-caller-identity --profile ghilbut-tofu-apply-for-management
aws sso login --profile ghilbut-tofu-apply-for-domains
aws sts get-caller-identity --profile ghilbut-tofu-apply-for-domains
aws sso login --profile ghilbut-tofu-apply-for-workloads
aws sts get-caller-identity --profile ghilbut-tofu-apply-for-workloads
aws sso login --profile ghilbut-tofu-apply-for-ultary-domains
aws sts get-caller-identity --profile ghilbut-tofu-apply-for-ultary-domains
```

permission set 할당은 계정 책임과 운영 인원에 따라 사용자 직접 할당 또는 그룹 할당을
선택한다. legacy permission set은 provider와 backend 전환을 검증한 후 제거한다.
