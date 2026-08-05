---
title: Domains infrastructure
---

# Domains infrastructure

`domains/tofu/`는 Domains account `869061964712`의 domain registration, Route 53,
CPA IAM OIDC provider와 DNS 전용 IAM role을 관리한다.

## Execution path

| Item | Value |
|---|---|
| Plan source profile | `ghilbut-tofu-plan-for-domains` |
| Apply source profile | `ghilbut-tofu-apply-for-domains` |
| Default execution role | `arn:aws:iam::869061964712:role/tofu-plan` |
| Local Apply execution role | `arn:aws:iam::869061964712:role/tofu-apply` |
| State key | `platform/domains.tfstate` |
| CDN remote state | `platform/aws/cdn.tfstate` read-only |

Backend와 CDN remote state는 SharedServices `tofu-state-readonly`를 수임한다. Apply backend는
`tofu-state-apply.tfbackend`로 SharedServices `tofu-state-apply`를 수임한다. Provider는 기본으로
Domains `tofu-plan`을 수임한다. Apply 전용 로컬 작업 공간은 `tofu-apply.auto.tfvars`로 Domains
`tofu-apply`를 지정한다.

## Profile

```sh
aws configure set sso_session ghilbut --profile ghilbut-tofu-plan-for-domains
aws configure set sso_account_id 869061964712 --profile ghilbut-tofu-plan-for-domains
aws configure set sso_role_name TofuPlanForDomains --profile ghilbut-tofu-plan-for-domains
aws configure set region us-east-1 --profile ghilbut-tofu-plan-for-domains

aws configure set sso_session ghilbut --profile ghilbut-tofu-apply-for-domains
aws configure set sso_account_id 869061964712 --profile ghilbut-tofu-apply-for-domains
aws configure set sso_role_name TofuApplyForDomains --profile ghilbut-tofu-apply-for-domains
aws configure set region us-east-1 --profile ghilbut-tofu-apply-for-domains

aws sso login --profile ghilbut-tofu-plan-for-domains
aws sso login --profile ghilbut-tofu-apply-for-domains
aws sts get-caller-identity --profile ghilbut-tofu-plan-for-domains
aws sts get-caller-identity --profile ghilbut-tofu-apply-for-domains
```

두 Caller account는 `869061964712`다.

## Plan and apply

DKIM 값은 state에서 읽고 shell output으로 출력하지 않는다. Override가 없는 checkout은 Plan
source와 기본 `tofu-plan` role을 사용한다.

```sh
export AWS_PROFILE=ghilbut-tofu-plan-for-domains
export AWS_SDK_LOAD_CONFIG=1

tofu -chdir=domains/tofu init -reconfigure

export TF_VAR_ghilbut_dkim_for_root_domain="$(
  tofu -chdir=domains/tofu state pull |
    jq -r '
      .resources[]
      | select(.type == "aws_route53_record" and .name == "google_dkim")
      | .instances[0].attributes.records[0]
    '
)"

tofu -chdir=domains/tofu plan -detailed-exitcode
unset TF_VAR_ghilbut_dkim_for_root_domain
```

Apply 전용 로컬 작업 공간의 `domains/tofu/tofu-apply.auto.tfvars`는 다음 값만 포함한다.

```hcl
aws_execution_role_arn = "arn:aws:iam::869061964712:role/tofu-apply"
```

이 파일은 git에서 제외된다. Apply source와 `tofu-apply`를 함께 사용한다.

```sh
export AWS_PROFILE=ghilbut-tofu-apply-for-domains
export AWS_SDK_LOAD_CONFIG=1

tofu -chdir=domains/tofu init -reconfigure \
  -backend-config=tofu-state-apply.tfbackend

export TF_VAR_ghilbut_dkim_for_root_domain="$(
  tofu -chdir=domains/tofu state pull |
    jq -r '
      .resources[]
      | select(.type == "aws_route53_record" and .name == "google_dkim")
      | .instances[0].attributes.records[0]
    '
)"

tofu -chdir=domains/tofu plan -out=/tmp/domains.tfplan
tofu -chdir=domains/tofu apply /tmp/domains.tfplan
unset TF_VAR_ghilbut_dkim_for_root_domain
```

## Verify

각 작업 공간에서 해당 DKIM 환경 변수 설정을 다시 실행한 뒤 `tofu plan`을 실행한다. 마지막
plan은 변경이 없다. `oidc.k3s.ghilbut.com` alias와 Platform certificate validation CNAME은
Domains state가 관리한다.
