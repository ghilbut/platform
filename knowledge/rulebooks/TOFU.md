---
type: rulebook
area: tofu
---

# OpenTofu 기준

이 문서는 모든 OpenTofu root가 공유하는 작성, 인증, state, CI 기준을 정의한다. root별 account, role ARN, state key와 실행 순서는 [[aws/README|AWS architecture]]와 해당 영역의 `RUNBOOK.md`가 관리한다.

## 문서와 코드의 책임

| 기록할 내용 | source of truth | 기록 방식 |
| --- | --- | --- |
| 모든 root에 공통인 작성, 인증, state, CI 기준 | 이 문서 | 공통 규칙만 기록한다. |
| account, role ARN, state key, root 소유자 | [AWS architecture](../../aws/README.md) | 표와 책임 설명으로 기록한다. |
| root의 backend, provider, variable, output | 해당 root의 `versions.tf`, `providers.tf`, `variables.tf`, `outputs.tf` | 실제 값을 선언한다. |
| root의 리소스 조합 | 해당 root의 `main.tf`와 module | resource와 의존성을 선언한다. |
| 실행 순서, source profile, 로컬 Apply file | 해당 영역의 `RUNBOOK.md` | 실행 명령과 검증을 기록한다. |
| CDN의 이름, tag와 CI 적용 범위 | [AWS CDN](../../aws/cdn/README.md) | CDN 전용 기준을 기록한다. |

실행 값과 shell command는 root 가까이 있는 실행 Runbook에 기록한다. token, private key, kubeconfig 인증서와 git 제외 Apply file의 값은 저장소에 기록하지 않는다.

## Root 작성

각 root는 다음 파일 구분을 사용한다.

| 파일 | 책임 |
| --- | --- |
| `versions.tf` | OpenTofu 버전, backend, required provider |
| `providers.tf` | provider와 root 공통 `default_tags` |
| `variables.tf` | 입력과 validation |
| `outputs.tf` | 다른 root가 소비하는 output |
| `main.tf` | resource와 module 조합 |

Module도 같은 파일 구분을 사용한다. 수명 주기나 권한 경계가 없는 wrapper module은 만들지 않는다.

## 인증과 실행 모드

`AWS_PROFILE`은 IAM Identity Center source identity를 선택한다. backend와 `terraform_remote_state`에는 고정 `profile`을 선언하지 않는다.

| 작업 | backend | provider | 로컬 파일 |
| --- | --- | --- |
| Plan | SharedServices `tofu-state-readonly` | account-local `tofu-plan` | 없음 |
| 일반 Apply | SharedServices `tofu-state-apply` | account-local `tofu-apply` | `tofu-apply.auto.tfvars`, `tofu-state-apply.tfbackend` |
| State 관리 Apply | SharedServices `tofu-state-apply` | SharedServices `tofu-state-admin` | `tofu-apply.auto.tfvars`, `tofu-state-apply.tfbackend` |
| 새 execution role bootstrap | SharedServices state role | source identity 직접 사용 | `bootstrap.tfvars` |
| UltaryDomains Plan 또는 Apply | SharedServices state role | source identity 직접 사용 | 없음 |

Account-local execution role을 사용하는 root는 `aws_execution_role_arn` variable을 선언한다. 기본값은 해당 account의 `tofu-plan` role ARN이다. Apply 전용 로컬 작업 공간은 git에서 제외한 `tofu-apply.auto.tfvars`에서 이 값을 `tofu-apply` role ARN으로 바꾼다. `TF_VAR_aws_execution_role_arn`은 사용하지 않는다.

`aws/shared-services/state/tofu/`의 Apply provider는 `tofu-state-admin`을 사용한다. CDN 배포 workflow는 `deployment.tfvars`로 `tofu-apply`를 사용한다. 새 account에서 execution role을 만들 때만 `bootstrap.tfvars`에 `aws_execution_role_arn = null`을 지정한다. 기존 account에서는 `null`을 사용하지 않는다.

Source profile, provider role 또는 backend role을 바꾸면 `tofu init -reconfigure`를 실행한다. Apply backend는 `-backend-config=tofu-state-apply.tfbackend`를 함께 지정한다. root별 source profile과 Apply role은 [[aws/RUNBOOK#Plan and apply|AWS 운영 Runbook]]에서 확인한다.

## State와 root 간 의존성

중앙 state bucket과 state role은 SharedServices가 소유한다. state object는 backend의 `tofu-state-readonly`와 `tofu-state-apply`만 사용한다. state bucket과 `tofu-state-admin`의 정확한 소유 root, state key와 role 경계는 [[aws/README#State ownership|AWS State ownership]]에서 관리한다.

- `terraform_remote_state`는 `tofu-state-readonly`를 사용한다.
- root 사이에는 필요한 식별자만 `terraform_remote_state` output으로 전달한다.
- 하나의 resource는 하나의 state만 관리한다.
- state bucket을 옮길 때는 중앙 state role도 함께 옮기거나 새 bucket policy가 중앙 state role을 허용하게 만든다.
- backend key를 옮길 때는 `tofu init -migrate-state`로 state만 옮긴다.
- 여러 state를 합칠 때는 선언형 import로 새 state를 완성하고 원격 식별자를 비교한 뒤 기존 state 주소를 제거한다.
- 원격 resource를 다시 만들지 않는다.

## 의존성과 CI

Module output을 input으로 전달하면 별도 `depends_on`을 쓰지 않는다. output으로 표현할 수 없는 의존성만 `depends_on`으로 선언한다.

GitHub Actions는 OIDC로 SharedServices `deployer`에 로그인한다. `deployer`와 Workloads permission set은 source identity이며 workload resource를 직접 관리하지 않는다. 실제 권한은 account-local execution role이 제공한다. 대상 계정과 role 경계는 [[aws/README#OpenTofu access|AWS OpenTofu access]]에서 관리한다.

| 구분 | 기준 |
| --- | --- |
| Changed Plan | `.github/workflows/tofu-plan-changed.yml`이 `main` push에서 변경된 CI 관리 root를 Plan한다. |
| Full Plan | `.github/workflows/tofu-plan-all.yml`이 수동 실행에서 CI 관리 root 전체를 Plan한다. |
| CI 인증 | 기본 backend와 provider만 사용한다. Apply override와 `TF_VAR_aws_execution_role_arn`, `TF_CLI_ARGS`, `TF_CLI_ARGS_init`, `TF_CLI_ARGS_plan`은 사용하지 않는다. |
| CI 대상 | 두 workflow의 `CI_MANAGED_TOFU_ROOTS`는 같은 목록과 순서를 사용한다. GitHub-hosted runner에서 재현 가능한 root만 등록한다. |
| 대상 변경 | 같은 target으로 `tofu plan -refresh-only`를 실행한다. 추가 권한은 모든 workload account execution role 정책에 함께 반영한다. |
