---
title: Domains infrastructure
---

# Domains infrastructure

`domains/tofu/`는 Domains account `869061964712`의 domain registration, Route 53,
CPA IAM OIDC provider와 DNS 전용 IAM role을 관리한다.

## Execution path

| Item | Value |
|---|---|
| Source profile | `ghilbut-tofu-apply-for-domains` |
| Permission set | `TofuApplyForDomains` |
| Execution role | `arn:aws:iam::869061964712:role/tofu-apply-domains` |
| State key | `platform/domains.tfstate` |
| CDN remote state | `platform/aws/cdn.tfstate` read-only |

`TofuApplyForDomains`와 `tofu-apply-domains`는 DNS와 이 root의 state에 필요한 권한만
가진다.

## Profile

```sh
aws configure set sso_session ghilbut --profile ghilbut-tofu-apply-for-domains
aws configure set sso_account_id 869061964712 --profile ghilbut-tofu-apply-for-domains
aws configure set sso_role_name TofuApplyForDomains --profile ghilbut-tofu-apply-for-domains
aws configure set region us-east-1 --profile ghilbut-tofu-apply-for-domains

aws sso login --profile ghilbut-tofu-apply-for-domains
aws sts get-caller-identity --profile ghilbut-tofu-apply-for-domains
```

Caller account는 `869061964712`다.

## Plan and apply

DKIM 값은 state에서 읽고 shell output으로 출력하지 않는다.

```sh
export AWS_PROFILE=ghilbut-tofu-apply-for-domains
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

tofu -chdir=domains/tofu plan
tofu -chdir=domains/tofu apply
unset TF_VAR_ghilbut_dkim_for_root_domain
```

## Verify

`Plan and apply` section의 DKIM 환경 변수 설정을 다시 실행한 뒤 `tofu plan`을 실행한다.
마지막 plan은 변경이 없다. `oidc.k3s.ghilbut.com` alias와 Platform certificate validation
CNAME은 Domains state가 관리한다.
