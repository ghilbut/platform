# GitHub

이 디렉터리는 GitHub와 연동되는 플랫폼 인프라 구성을 관리합니다.

## GitHub Actions OIDC

`tofu/`는 SharedServices 계정에서 공유하는 GitHub Actions OIDC provider를 관리합니다.
provider URL은 `https://token.actions.githubusercontent.com`이고, 허용 audience는
`sts.amazonaws.com`입니다.

AWS 계정에서는 같은 OIDC provider URL을 하나만 등록할 수 있습니다. 따라서 provider는
여기에서 한 번만 관리하고, CDN 같은 개별 서비스 구성은 `platform/github.tfstate`의 output을
읽어 전용 IAM 역할을 만듭니다.

각 서비스 역할은 다음을 직접 관리해야 합니다.

- 필요한 AWS 권한만 포함한 정책
- `repository`, `branch`, `tag`, `environment` 등으로 제한한 trust policy 조건

이 분리는 CDN을 변경하거나 제거해도 다른 서비스의 GitHub Actions 신뢰 기반에 영향을
주지 않게 합니다.

## Plan과 Apply

GitHub Actions OIDC를 처음 사용하는 서비스보다 먼저 적용합니다.

Override가 없는 checkout은 Plan source와 기본 `tofu-plan` role을 사용합니다.

```sh
AWS_PROFILE=ghilbut-tofu-plan-for-workloads AWS_SDK_LOAD_CONFIG=1 \
  tofu -chdir=github/tofu init -reconfigure
AWS_PROFILE=ghilbut-tofu-plan-for-workloads AWS_SDK_LOAD_CONFIG=1 \
  tofu -chdir=github/tofu plan -detailed-exitcode
```

Apply 전용 로컬 작업 공간의 `github/tofu/tofu-apply.auto.tfvars`는 다음 값을 포함합니다.

```hcl
aws_execution_role_arn = "arn:aws:iam::012646747332:role/tofu-apply"
```

```sh
AWS_PROFILE=ghilbut-tofu-apply-for-workloads AWS_SDK_LOAD_CONFIG=1 \
  tofu -chdir=github/tofu init -reconfigure
AWS_PROFILE=ghilbut-tofu-apply-for-workloads AWS_SDK_LOAD_CONFIG=1 \
  tofu -chdir=github/tofu plan -out=/tmp/github.tfplan
AWS_PROFILE=ghilbut-tofu-apply-for-workloads AWS_SDK_LOAD_CONFIG=1 \
  tofu -chdir=github/tofu apply /tmp/github.tfplan
```

OpenTofu 상태는 `s3://ghilbut-tfstates/platform/github.tfstate`에 저장됩니다. Backend는
`AWS_PROFILE`을 사용하고 provider는 Plan에서 `tofu-plan`, Apply에서 `tofu-apply`를 수임합니다.
