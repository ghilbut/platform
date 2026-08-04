---
title: Platform workload access
---

# Platform workload access

`aws/foundation/workload/tofu/`는 Platform account `012646747332`의 `tofu-apply` 역할과
CPA IAM OIDC provider를 관리한다.

## Profile

```sh
aws configure set sso_session ghilbut --profile ghilbut-tofu-apply-for-workloads
aws configure set sso_account_id 012646747332 --profile ghilbut-tofu-apply-for-workloads
aws configure set sso_role_name TofuApplyForWorkloads --profile ghilbut-tofu-apply-for-workloads
aws configure set region us-east-1 --profile ghilbut-tofu-apply-for-workloads

aws sso login --profile ghilbut-tofu-apply-for-workloads
aws sts get-caller-identity --profile ghilbut-tofu-apply-for-workloads
```

Caller account는 `012646747332`다.

## Apply

```sh
export AWS_PROFILE=ghilbut-tofu-apply-for-workloads
export AWS_SDK_LOAD_CONFIG=1

tofu -chdir=aws/foundation/workload/tofu init -reconfigure
tofu -chdir=aws/foundation/workload/tofu plan
tofu -chdir=aws/foundation/workload/tofu apply
```

이 root는 `tofu-apply` 역할 자체를 관리하므로 provider에서 그 역할을 수임하지 않는다.

## Verify

```sh
AWS_PROFILE=ghilbut-tofu-apply-for-workloads aws iam get-role --role-name tofu-apply

AWS_PROFILE=ghilbut-tofu-apply-for-workloads aws iam get-open-id-connect-provider \
  --open-id-connect-provider-arn \
  arn:aws:iam::012646747332:oidc-provider/oidc.k3s.ghilbut.com/cpa

AWS_PROFILE=ghilbut-tofu-apply-for-workloads tofu -chdir=aws/foundation/workload/tofu plan
```

마지막 plan은 변경이 없다.
