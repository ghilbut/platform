# OpenTofu Conventions

## Root 구성

- `versions.tf`에는 버전, backend, required providers만 둔다.
- `providers.tf`에는 provider와 root 공통 `default_tags`만 둔다.
- `variables.tf`, `outputs.tf`, `main.tf`는 입력, 외부 소비 output, 조합·리소스 선언으로
  구분한다.
- module도 이 파일 구분을 따르며, 수명 주기나 권한 경계가 없는 wrapper module은 만들지
  않는다.

## AWS credential 선택

- S3 backend는 SharedServices의 `tofu-state-readonly` role을 기본으로 수임한다. Apply는 git에서
  제외한 `tofu-state-apply.tfbackend`로 `tofu-state-apply` role을 수임한다.
- `terraform_remote_state`는 SharedServices의 `tofu-state-readonly` role을 수임한다.
- Backend와 `terraform_remote_state`는 고정 `profile`을 선언하지 않는다. `AWS_PROFILE`이 IAM
  Identity Center source identity를 선택한다.
- Account-local execution role이 있는 root는 `aws_execution_role_arn` 변수를 사용한다. 기본값은
  해당 account의 `tofu-plan` role ARN이다.
- Apply 전용 로컬 작업 공간은 git에서 제외한 `tofu-apply.auto.tfvars`에서 같은 변수에
  `tofu-apply` role ARN을 지정한다. `TF_VAR_aws_execution_role_arn`은 사용하지 않는다.
- `aws/shared-services/state/tofu/`의 Apply 전용 로컬 variable file은 `tofu-state-admin` role ARN을
  지정한다.
- `aws_execution_role_arn = null`은 execution role을 생성하는 새 account bootstrap에서만
  source identity를 provider에 직접 사용한다. 기존 account에서는 `null`을 사용하지 않는다.
- CDN 배포 workflow는 `deployment.tfvars`로 `tofu-apply`를 provider에서 수임한다.
- Source identity와 execution role의 작업 종류를 일치시킨다. Plan source는 `tofu-plan`, Apply
  source는 일반 root에서 `tofu-apply`, state 관리 root에서 `tofu-state-admin`을 사용한다.
- Source profile이나 backend role을 바꾼 뒤에는 `tofu init -reconfigure`를 실행한다. Apply
  backend는 `-backend-config=tofu-state-apply.tfbackend`를 함께 지정한다.
- UltaryDomains provider는 account-local execution role 없이 `AWS_PROFILE`의 source identity를
  직접 사용한다. Backend는 다른 root와 같은 중앙 state role을 사용한다.

## 상태 소유권

- 중앙 state role과 state bucket은 SharedServices 계정에 함께 둔다. State bucket을 다른 계정으로
  옮기면 중앙 state role도 함께 옮기거나 새 bucket policy에 중앙 state role을 허용한다.
- `tofu-state-admin`은 state bucket 설정과 자신의 IAM role trust policy, 설명, session duration,
  tag, inline policy를 관리한다. State object API의 직접 IAM 권한은 없지만 bucket policy를 통한
  다른 principal의 object 접근 위임은 변경할 수 있다. State object는 backend의
  `tofu-state-readonly`와 `tofu-state-apply`가 사용한다.
- `aws/shared-services/state/tofu/`는 `platform/aws/shared-services/state.tfstate`를 사용하며 active
  state bucket과 `tofu-state-admin`을 관리한다. `aws/shared-services/tofu/`는 중앙 backend role을
  관리한다.
- `aws/shared-services/tofu/`는 `deployer`와 GitHub Actions OIDC provider를 함께 관리한다.
- SharedServices의 `deployer`가 CI/CD source identity를 제공한다. GitHub repository variable은
  실행 Runbook에서 `gh variable set`으로 관리한다.
- Foundation account ID처럼 root 사이에 필요한 식별자만 `terraform_remote_state` output으로
  소비한다. 한 리소스를 두 state에서 선언하지 않는다.
- 하나의 backend key를 옮길 때는 `tofu init -migrate-state`로 state만 이전한다.
- 여러 state를 하나로 합칠 때는 선언형 import로 새 state를 완성하고 원격 식별자를 비교한
  다음 기존 state 주소를 제거한다. 원격 리소스는 다시 만들지 않는다.

## AWS CDN 태그와 이름

- CDN root provider `default_tags`는 `created_by`, `managed_by`, `project`, `service`,
  `opentofu/repo`, `opentofu/path`을 제공한다.
- CDN module은 `local.default_tags`에 `opentofu/module/repo`,
  `opentofu/module/path`만 추가한다. `var.default_tags`를 module input으로 전달하지
  않는다.
- CDN 리소스 이름과 `Name` 태그는 `cdn-platform`을 기준으로 한다. 저장소 소유자를
  중복한 `ghilbut-` 접두사는 S3의 전역 버킷 이름처럼 충돌 방지가 필요한 경우에만 쓴다.
- S3 객체에는 `Name` 태그를 붙이지 않는다. 객체 태그는 10개 제한을 넘지 않아야 한다.

## 의존성과 CI

- module output을 input으로 전달하면 별도 `depends_on`을 쓰지 않는다. output으로 표현할
  수 없는 의존성만 `depends_on`으로 선언한다.
- CDN CI는 `404.html`, `503.html`, `lambda.zip`, Lambda@Edge, CloudFront 배포판만
  대상으로 적용한다. IAM·DNS·ACM·CloudFront Function 변경은 로컬 apply의 책임이다.
- CDN Lambda bundle은 git에서 관리한다. CI는 build 결과가 저장소와 일치하는지 확인한 뒤
  Lambda bundle을 적용한다.
- `deployer`는 Management, SharedServices, SecurityTooling과 Domains의 `tofu-plan`·`tofu-apply`,
  SharedServices의 `tofu-state-admin` 및 공용 state role만 수임한다. 실제 읽기·쓰기 권한은 수임한
  role이 제공한다.
- Workloads permission set과 `deployer`는 workload resource를 직접 관리하지 않는다. 두 source
  identity는 동일한 account-local execution role을 수임하여 같은 인가를 사용한다.
- 모든 workload account의 `tofu-plan`은 `ReadOnlyAccess`를 사용한다. 모든 workload account의
  `tofu-apply`는 `PowerUserAccess`, `IAMFullAccess`와 중앙 관리 기능 거부 정책을 사용한다.
- Workload account는 SharedServices와 SecurityTooling이다. Management와 Domains는 각각
  Foundation과 DNS 전용 인가 정책을 사용한다.
- Workload `tofu-plan`은 `ghilbut-tfstates`와 `ghilbut-tfstates-v2`의 객체를 직접 읽지 못한다.
  Backend는 `tofu-state-readonly`를 별도로 수임한다.
- Workload `tofu-apply`는 `ghilbut-tfstates`와 `ghilbut-tfstates-v2`의 bucket API와 object API를
  직접 사용할 수 없다. `tofu-state-admin`도 수임하거나 변경할 수 없다. Backend는
  `tofu-state-apply`를 별도로 수임한다.
- Domains `tofu-apply`의 `iam:UpdateAssumeRolePolicy`는 자신의 trust policy에만 적용한다.
- GitHub OIDC는 현재 `deployer`에 로그인한다. Tekton은 같은 role trust에 인증 방식을 추가한다.
- `scripts/opentofu-plan-roots.sh`는 전체 또는 Git revision 사이에서 변경된 CI 관리 root를
  선택한다. `scripts/opentofu-plan.sh`는 전달받은 root를 순서대로 Plan하고 모든 실패 root를
  출력한다. GitHub Actions와 Tekton은 이 두 스크립트를 함께 사용한다.
- CI Plan은 기본 backend와 provider 설정만 사용한다. `tofu-apply.auto.tfvars`,
  `tofu-state-apply.tfbackend`, `TF_VAR_aws_execution_role_arn`, `TF_CLI_ARGS`, `TF_CLI_ARGS_init`과
  `TF_CLI_ARGS_plan`을 사용하지 않는다.
- CI 관리 root는 `scripts/opentofu-plan-roots.txt`에서 관리한다. GitHub-hosted runner에서 같은
  입력과 네트워크를 재현할 수 있는 root만 등록한다.
- CI target 집합을 바꾸면 같은 target으로 `tofu plan -refresh-only`를 실행한다. 추가 권한이
  필요하면 모든 workload account의 execution role 정책을 함께 변경한다.
