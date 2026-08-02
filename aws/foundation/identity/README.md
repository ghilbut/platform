---
title: IAM Identity Center
---

# IAM Identity Center

`tofu/`는 IAM Identity Center permission set과 AWS 계정 할당을 관리한다. 기존 `tofu`
permission set은 새 역할별 permission set의 로그인을 검증할 때까지 유지한다.

| Permission set | 대상 계정 | Principal | 책임 |
|---|---|---|---|
| `foundation-management` | management | `devops` 그룹 | Organizations, 계정, 결제, IAM Identity Center 관리 |
| `platform-operator` | platform | `ghilbut` 사용자 | 플랫폼 워크로드 인프라 관리 |
| `ultary-domains-operator` | ultary-domains | `ghilbut` 사용자 | 도메인 등록과 Route 53 DNS 관리 |

## CLI profile migration

새 permission set을 적용한 뒤 기존 `tofu` profile을 유지한 상태에서 새 profile로 로그인을
검증한다. 세 프로필이 정상 동작하는 것을 확인한 후에만 기존 profile의 role name을 교체한다.

```sh
aws configure set sso_role_name foundation-management --profile ghilbut
aws configure set sso_role_name platform-operator --profile ghilbut-platform
aws configure set sso_role_name ultary-domains-operator --profile ultary-domains

aws sso login --profile ghilbut
aws sts get-caller-identity --profile ghilbut
aws sso login --profile ghilbut-platform
aws sts get-caller-identity --profile ghilbut-platform
aws sso login --profile ultary-domains
aws sts get-caller-identity --profile ultary-domains
```

이 단계는 기존 `tofu` permission set을 삭제하지 않는다. 검증이 완료되면 다음 변경에서
기존 permission set과 기존 할당을 제거한다.
