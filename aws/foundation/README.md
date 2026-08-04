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
| `state/tofu/` | 공유 OpenTofu state bucket의 cross-account 접근 정책 | `platform/aws/foundation/state.tfstate` |
| `organizations/tofu/` | OU, SCP, delegated administrator | `platform/aws/foundation/organizations.tfstate` |

`accounts/tofu/`, `identity/tofu/`, `state/tofu/`가 현재 존재한다. `organizations/tofu/`는
Foundation 전환 작업에 따라 추가한다.

`accounts/tofu/modules/management/`는 management 계정 자체의 opt-in 리전만 관리한다.
따라서 Account Management API를 standalone context로 호출하며, AWS Organizations의
Account Management trusted access를 활성화하지 않는다.

`identity/tofu/`는 IAM Identity Center permission set, AWS 관리형 정책 연결, 계정 할당,
Foundation 운영 그룹과 그 멤버십을 관리한다. Identity Store의 사용자와 그 밖의 그룹은 외부
IdP 또는 IAM Identity Center의 소유이며, 이 state에서 생성하거나 삭제하지 않는다.

`state/tofu/`는 Platform 계정이 소유한 `ghilbut-tfstates` bucket policy를 관리한다.
Management source permission set에는 Foundation accounts·identity state와 lock file에만
cross-account 접근을 허용한다. state bucket의 lifecycle과 그 밖의 state key는 관리하지
않는다.

## OpenTofu 실행

`state/tofu/`는 Platform의 `TofuApplyForWorkloads` source profile로 backend에 접근하고,
Platform `tofu-apply` 역할을 수임해 bucket policy를 관리한다.

Foundation accounts·identity state의 backend는 `TofuApplyForManagement` source profile로
state에 접근하고, AWS provider는 이어서 Management 계정의 `tofu-apply` 역할을 수임한다.
실행 환경에서 source profile을 선택하고 AWS SDK가 shared config를 읽도록 설정한다.

```sh
export AWS_PROFILE=ghilbut-tofu-apply-for-workloads
export AWS_SDK_LOAD_CONFIG=1

cd aws/foundation/state/tofu
tofu init -reconfigure
tofu plan
tofu apply

export AWS_PROFILE=ghilbut-tofu-apply-for-management

cd ../../accounts/tofu
tofu init -reconfigure
tofu plan
tofu apply

cd ../../identity/tofu
tofu init -reconfigure
tofu plan
tofu apply
```

## Accounts state migration

기존 `platform/aws/accounts.tfstate` 상태를 새 backend key로 이전할 때는
`accounts/tofu/`에서 다음 명령을 실행한다.

```sh
tofu init -migrate-state
```

리소스를 새로 만들거나 import하지 않는다. OpenTofu 작업 절차는
[OpenTofu 규칙](../../docs/TOFU.md)을 따른다.
