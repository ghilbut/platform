---
title: Platform workload access runbook
type: runbook
area: aws-foundation
tags:
  - aws
  - iam
  - migration
---

# Platform workload access runbook

이 Runbook은 Domains 계정 이름 정리, 새 Platform 계정 생성, 임시 이중 workload 접근,
Platform `tofu-apply` 역할 생성을 순서대로 실행한다. 모든 명령은 repository root에서
실행한다.

## 1. Domains workload profile 보존

기존 Domains workload 접근을 임시 profile로 유지한다.

```sh
aws configure set sso_session ghilbut --profile ghilbut-tofu-apply-for-workloads-domains
aws configure set sso_account_id 869061964712 --profile ghilbut-tofu-apply-for-workloads-domains
aws configure set sso_role_name TofuApplyForWorkloads --profile ghilbut-tofu-apply-for-workloads-domains
aws configure set region us-east-1 --profile ghilbut-tofu-apply-for-workloads-domains

aws sso login --profile ghilbut-tofu-apply-for-workloads-domains
aws sts get-caller-identity --profile ghilbut-tofu-apply-for-workloads-domains
```

## 2. AWS Organizations account 적용

```sh
export AWS_SDK_LOAD_CONFIG=1
export AWS_PROFILE=ghilbut-tofu-apply-for-management

tofu -chdir=aws/foundation/accounts/tofu init -reconfigure
tofu -chdir=aws/foundation/accounts/tofu plan
tofu -chdir=aws/foundation/accounts/tofu apply

platform_account_id="$(tofu -chdir=aws/foundation/accounts/tofu output -raw platform_account_id)"
aws organizations describe-account --account-id "${platform_account_id}"
```

## 3. Platform state 접근 정책 적용

```sh
export AWS_PROFILE=ghilbut-tofu-apply-for-workloads-domains

tofu -chdir=aws/foundation/state/tofu init -reconfigure
tofu -chdir=aws/foundation/state/tofu plan
tofu -chdir=aws/foundation/state/tofu apply
```

## 4. Workload permission set 이중 할당

```sh
export AWS_PROFILE=ghilbut-tofu-apply-for-management

tofu -chdir=aws/foundation/identity/tofu init -reconfigure
tofu -chdir=aws/foundation/identity/tofu plan
tofu -chdir=aws/foundation/identity/tofu apply
```

## 5. Platform workload profile 구성

```sh
platform_account_id="$(tofu -chdir=aws/foundation/accounts/tofu output -raw platform_account_id)"

aws configure set sso_session ghilbut --profile ghilbut-tofu-apply-for-workloads
aws configure set sso_account_id "${platform_account_id}" --profile ghilbut-tofu-apply-for-workloads
aws configure set sso_role_name TofuApplyForWorkloads --profile ghilbut-tofu-apply-for-workloads
aws configure set region us-east-1 --profile ghilbut-tofu-apply-for-workloads

aws sso login --profile ghilbut-tofu-apply-for-workloads
aws sts get-caller-identity --profile ghilbut-tofu-apply-for-workloads
```

## 6. Platform workload 실행 역할 적용

`workload/tofu/` provider는 자신이 관리하는 `tofu-apply` 역할을 수임하지 않는다.
`TofuApplyForWorkloads` source profile로 역할을 생성하고 이후 workload root가 이 역할을
수임한다.

```sh
export AWS_PROFILE=ghilbut-tofu-apply-for-workloads

tofu -chdir=aws/foundation/workload/tofu init -reconfigure
tofu -chdir=aws/foundation/workload/tofu plan
tofu -chdir=aws/foundation/workload/tofu apply
tofu -chdir=aws/foundation/workload/tofu plan

aws iam get-role --role-name tofu-apply
```

마지막 plan은 변경 사항이 없어야 한다. Domains workload 접근은
`ghilbut-tofu-apply-for-workloads-domains`로 계속 사용할 수 있어야 한다.
