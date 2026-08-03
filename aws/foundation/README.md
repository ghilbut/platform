---
title: AWS Foundation
---

# AWS Foundation

AWS Foundation은 AWS 계정 수명 주기, IAM Identity Center 접근 권한, AWS Organizations
거버넌스를 관리한다. 각 책임은 별도 OpenTofu 상태로 관리한다.

| 경로 | 책임 | Backend key |
|---|---|---|
| `accounts/tofu/` | AWS Organizations 계정 수명 주기와 관리 계정 opt-in 리전 | `platform/aws/foundation/accounts.tfstate` |
| `identity/tofu/` | IAM Identity Center 권한 세트와 계정 할당 | `platform/aws/foundation/identity.tfstate` |
| `organizations/tofu/` | OU, SCP, delegated administrator | `platform/aws/foundation/organizations.tfstate` |

`accounts/tofu/`와 `identity/tofu/`가 현재 존재한다. `organizations/tofu/`는 Foundation
전환 작업에 따라 추가한다.

`accounts/tofu/modules/management/`는 management 계정 자체의 opt-in 리전만 관리한다.
따라서 Account Management API를 standalone context로 호출하며, AWS Organizations의
Account Management trusted access를 활성화하지 않는다.

`identity/tofu/`는 IAM Identity Center permission set, AWS 관리형 정책 연결, 계정 할당,
Foundation 운영 그룹과 그 멤버십을 관리한다. Identity Store의 사용자와 그 밖의 그룹은 외부
IdP 또는 IAM Identity Center의 소유이며, 이 state에서 생성하거나 삭제하지 않는다.

## Accounts state migration

기존 `platform/aws/accounts.tfstate` 상태를 새 backend key로 이전할 때는
`accounts/tofu/`에서 다음 명령을 실행한다.

```sh
tofu init -migrate-state
```

리소스를 새로 만들거나 import하지 않는다. OpenTofu 작업 절차는
[OpenTofu 규칙](../../docs/TOFU.md)을 따른다.
