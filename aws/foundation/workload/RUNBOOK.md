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

이 Runbook은 Domains와 Platform의 workload 접근을 확인하고 AWS Foundation root를
순서대로 적용한다. 모든 명령은 repository root에서 실행한다.

## 1. Workload profile 구성

```sh
aws configure set sso_session ghilbut --profile ghilbut-tofu-apply-for-workloads-domains
aws configure set sso_account_id 869061964712 --profile ghilbut-tofu-apply-for-workloads-domains
aws configure set sso_role_name TofuApplyForWorkloads --profile ghilbut-tofu-apply-for-workloads-domains
aws configure set region us-east-1 --profile ghilbut-tofu-apply-for-workloads-domains

aws configure set sso_session ghilbut --profile ghilbut-tofu-apply-for-workloads
aws configure set sso_account_id 012646747332 --profile ghilbut-tofu-apply-for-workloads
aws configure set sso_role_name TofuApplyForWorkloads --profile ghilbut-tofu-apply-for-workloads
aws configure set region us-east-1 --profile ghilbut-tofu-apply-for-workloads

aws sso login --profile ghilbut-tofu-apply-for-workloads-domains
aws sts get-caller-identity --profile ghilbut-tofu-apply-for-workloads-domains
aws sso login --profile ghilbut-tofu-apply-for-workloads
aws sts get-caller-identity --profile ghilbut-tofu-apply-for-workloads
```

## 2. Foundation root 적용

`workload/tofu/` provider는 자신이 관리하는 `tofu-apply` 역할을 수임하지 않는다.
Platform의 `TofuApplyForWorkloads` source profile로 역할을 관리한다.

```sh
export AWS_SDK_LOAD_CONFIG=1
export AWS_PROFILE=ghilbut-tofu-apply-for-management

tofu -chdir=aws/foundation/accounts/tofu init -reconfigure
tofu -chdir=aws/foundation/accounts/tofu plan
tofu -chdir=aws/foundation/accounts/tofu apply

export AWS_PROFILE=ghilbut-tofu-apply-for-workloads-domains

tofu -chdir=aws/foundation/state/tofu init -reconfigure
tofu -chdir=aws/foundation/state/tofu plan
tofu -chdir=aws/foundation/state/tofu apply

export AWS_PROFILE=ghilbut-tofu-apply-for-management

tofu -chdir=aws/foundation/identity/tofu init -reconfigure
tofu -chdir=aws/foundation/identity/tofu plan
tofu -chdir=aws/foundation/identity/tofu apply

export AWS_PROFILE=ghilbut-tofu-apply-for-workloads

tofu -chdir=aws/foundation/workload/tofu init -reconfigure
tofu -chdir=aws/foundation/workload/tofu plan
tofu -chdir=aws/foundation/workload/tofu apply
```

## 3. 검증

accounts, identity, state, workload의 plan은 변경 사항이 없어야 한다. Platform profile의
`aws iam get-role --role-name tofu-apply`는 `tofu-apply` 역할을 반환해야 한다. Domains
profile은 `aws/cdn/tofu`의 AWS 리소스를 읽을 수 있어야 한다.
