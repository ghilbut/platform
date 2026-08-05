---
title: AWS operations
---

# AWS operations

현재 계정, root와 접근 관계는 [AWS architecture](README.md)를 따른다. 모든 명령은 저장소
root에서 실행한다.

## Source profiles

먼저 이름이 `ghilbut`인 IAM Identity Center session을 만든다.

```sh
aws configure sso-session
```

| Prompt | Value |
|---|---|
| SSO session name | `ghilbut` |
| SSO start URL | `https://ghilbut.awsapps.com/start` |
| SSO region | `us-east-1` |
| SSO registration scopes | `sso:account:access` |

네 source profile을 같은 session에 연결한다.

```sh
aws configure set sso_session ghilbut --profile ghilbut-tofu-apply-for-management
aws configure set sso_account_id 384959722788 --profile ghilbut-tofu-apply-for-management
aws configure set sso_role_name TofuApplyForManagement --profile ghilbut-tofu-apply-for-management
aws configure set region us-east-1 --profile ghilbut-tofu-apply-for-management

aws configure set sso_session ghilbut --profile ghilbut-tofu-apply-for-workloads
aws configure set sso_account_id 012646747332 --profile ghilbut-tofu-apply-for-workloads
aws configure set sso_role_name TofuApplyForWorkloads --profile ghilbut-tofu-apply-for-workloads
aws configure set region us-east-1 --profile ghilbut-tofu-apply-for-workloads

aws configure set sso_session ghilbut --profile ghilbut-tofu-apply-for-domains
aws configure set sso_account_id 869061964712 --profile ghilbut-tofu-apply-for-domains
aws configure set sso_role_name TofuApplyForDomains --profile ghilbut-tofu-apply-for-domains
aws configure set region us-east-1 --profile ghilbut-tofu-apply-for-domains

aws configure set sso_session ghilbut --profile ghilbut-tofu-apply-for-ultary-domains
aws configure set sso_account_id 971119963968 --profile ghilbut-tofu-apply-for-ultary-domains
aws configure set sso_role_name TofuApplyForUltaryDomains --profile ghilbut-tofu-apply-for-ultary-domains
aws configure set region us-east-1 --profile ghilbut-tofu-apply-for-ultary-domains
```

로그인하고 계정 ID를 확인한다.

```sh
export AWS_SDK_LOAD_CONFIG=1

aws sso login --profile ghilbut-tofu-apply-for-management
aws sso login --profile ghilbut-tofu-apply-for-workloads
aws sso login --profile ghilbut-tofu-apply-for-domains
aws sso login --profile ghilbut-tofu-apply-for-ultary-domains

aws sts get-caller-identity --profile ghilbut-tofu-apply-for-management \
  --query Account --output text
aws sts get-caller-identity --profile ghilbut-tofu-apply-for-workloads \
  --query Account --output text
aws sts get-caller-identity --profile ghilbut-tofu-apply-for-domains \
  --query Account --output text
aws sts get-caller-identity --profile ghilbut-tofu-apply-for-ultary-domains \
  --query Account --output text
```

결과 순서는 `384959722788`, `012646747332`, `869061964712`, `971119963968`이다.

## Execution order

| 순서 | Root | Profile | Provider access | 선행 조건 |
|---:|---|---|---|---|
| 1 | `aws/foundation/accounts/tofu/` | Management | Management `tofu-apply` | 없음 |
| 2 | `aws/foundation/identity/tofu/` | Management | Management `tofu-apply` | accounts state |
| 3 | `aws/platform/tofu/` | Workloads | direct source와 SharedServices `tofu-apply` | SharedServices의 `TofuApplyForWorkloads` assignment |
| 4 | `github/tofu/` | Workloads | SharedServices `tofu-apply` | SharedServices role |
| 5 | `aws/cdn/tofu/` | Workloads | SharedServices `tofu-apply` | GitHub OIDC provider |
| 6 | `k3s/tofu/` | Workloads | direct source | CDN origin bucket와 `cpa` Kubernetes API |
| 7 | `domains/tofu/` | Domains | Domains `tofu-apply` | CDN state |
| 8 | `apps/tofu/` | Workloads | direct source | SharedServices의 `TofuApplyForWorkloads` assignment |
| 9 | `ultary/domains/tofu/` | UltaryDomains | direct source | UltaryDomains assignment |

## Plan and apply

### Required variables

Domains DKIM 값은 기존 state에서 읽고 shell output으로 출력하지 않는다.

```sh
AWS_PROFILE=ghilbut-tofu-apply-for-domains \
  tofu -chdir=domains/tofu init -reconfigure

export TF_VAR_ghilbut_dkim_for_root_domain="$(
  AWS_PROFILE=ghilbut-tofu-apply-for-domains \
    tofu -chdir=domains/tofu state pull \
    | jq -r '
        .resources[]
        | select(.type == "aws_route53_record" and .name == "google_dkim")
        | .instances[0].attributes.records[0]
      '
)"
```

UltaryDomains는 다음 필수 variable을 승인된 로컬 환경 변수나 git에서 제외한 variable file로
제공한다. Map variable의 환경 변수 값은 JSON object다.

- `ultary_co_dkim_for_root_domain`
- `ultary_co_txt_for_sub_domains`
- `ultary_co_cname_for_sub_domains`
- `ultary_co_dkim_for_sub_domains`

### Apply current infrastructure

현재 리소스가 존재하는 운영 환경에서는 각 root의 saved plan을 순서대로 한 번 적용한다.
CDN certificate를 새로 만드는 복구 작업은 certificate 요청, Domains validation record,
certificate validation과 CDN 순서로 나누어 실행한다.

```sh
apply_root() {
  profile_name="$1"
  root_path="$2"
  plan_path="$3"

  AWS_PROFILE="$profile_name" AWS_SDK_LOAD_CONFIG=1 \
    tofu -chdir="$root_path" init -reconfigure
  AWS_PROFILE="$profile_name" AWS_SDK_LOAD_CONFIG=1 \
    tofu -chdir="$root_path" validate
  AWS_PROFILE="$profile_name" AWS_SDK_LOAD_CONFIG=1 \
    tofu -chdir="$root_path" plan -out="$plan_path"
  AWS_PROFILE="$profile_name" AWS_SDK_LOAD_CONFIG=1 \
    tofu -chdir="$root_path" apply "$plan_path"
}

apply_root ghilbut-tofu-apply-for-management \
  aws/foundation/accounts/tofu /tmp/aws-foundation-accounts.tfplan
apply_root ghilbut-tofu-apply-for-management \
  aws/foundation/identity/tofu /tmp/aws-foundation-identity.tfplan
apply_root ghilbut-tofu-apply-for-workloads \
  aws/platform/tofu /tmp/aws-platform.tfplan
apply_root ghilbut-tofu-apply-for-workloads \
  github/tofu /tmp/github.tfplan
```

CDN apply 전에 Lambda bundle을 만든다.

```sh
pnpm install --frozen-lockfile
pnpm --filter @ghilbut/cdn-lambda build

apply_root ghilbut-tofu-apply-for-workloads \
  aws/cdn/tofu /tmp/aws-cdn.tfplan
```

K3s apply 전에 `cpa` Kubernetes API 연결을 확인한다.

```sh
kubectl --context cpa cluster-info

apply_root ghilbut-tofu-apply-for-workloads \
  k3s/tofu /tmp/k3s.tfplan
apply_root ghilbut-tofu-apply-for-domains \
  domains/tofu /tmp/domains.tfplan
apply_root ghilbut-tofu-apply-for-workloads \
  apps/tofu /tmp/apps.tfplan

export TF_VAR_aws_profile=ghilbut-tofu-apply-for-ultary-domains
apply_root ghilbut-tofu-apply-for-ultary-domains \
  ultary/domains/tofu /tmp/ultary-domains.tfplan
unset TF_VAR_aws_profile
```

## IAM Identity Center verification

Identity 변경 후 새 provisioning request를 확인한다.

```sh
AWS_PROFILE=ghilbut-tofu-apply-for-management AWS_SDK_LOAD_CONFIG=1 \
  aws sso-admin list-permission-set-provisioning-status \
    --instance-arn arn:aws:sso:::instance/ssoins-7223d00af1910289 \
    --max-results 20 \
    --query 'PermissionSetsProvisioningStatus[].{Status:Status,RequestId:RequestId,CreatedDate:CreatedDate}'
```

Identity apply가 생성한 모든 request의 `Status`는 `SUCCEEDED`여야 한다.

## Execution role verification

```sh
aws sts assume-role \
  --profile ghilbut-tofu-apply-for-management \
  --role-arn arn:aws:iam::384959722788:role/tofu-apply \
  --role-session-name verify-management-tofu-apply \
  --query 'AssumedRoleUser.Arn' --output text

aws sts assume-role \
  --profile ghilbut-tofu-apply-for-workloads \
  --role-arn arn:aws:iam::012646747332:role/tofu-apply \
  --role-session-name verify-shared-services-tofu-apply \
  --query 'AssumedRoleUser.Arn' --output text

aws sts assume-role \
  --profile ghilbut-tofu-apply-for-domains \
  --role-arn arn:aws:iam::869061964712:role/tofu-apply \
  --role-session-name verify-domains-tofu-apply \
  --query 'AssumedRoleUser.Arn' --output text
```

## State verification

다음 명령은 active state object만 출력한다. 결과는
[[aws/README#State ownership|State ownership]] 표의 아홉 key와 일치해야 한다.

```sh
AWS_PROFILE=ghilbut-tofu-apply-for-workloads AWS_SDK_LOAD_CONFIG=1 \
  aws s3api list-objects-v2 \
    --bucket ghilbut-tfstates \
    --query 'Contents[?ends_with(Key, `.tfstate`) && !starts_with(Key, `recovery/`)].Key' \
    --output text
```

적용한 모든 root의 최종 plan은 변경이 없어야 한다.

```sh
verify_root() {
  profile_name="$1"
  root_path="$2"

  AWS_PROFILE="$profile_name" AWS_SDK_LOAD_CONFIG=1 \
    tofu -chdir="$root_path" plan -detailed-exitcode
}

verify_root ghilbut-tofu-apply-for-management aws/foundation/accounts/tofu
verify_root ghilbut-tofu-apply-for-management aws/foundation/identity/tofu
verify_root ghilbut-tofu-apply-for-workloads aws/platform/tofu
verify_root ghilbut-tofu-apply-for-workloads github/tofu
verify_root ghilbut-tofu-apply-for-workloads aws/cdn/tofu
verify_root ghilbut-tofu-apply-for-workloads k3s/tofu
verify_root ghilbut-tofu-apply-for-domains domains/tofu
verify_root ghilbut-tofu-apply-for-workloads apps/tofu

export TF_VAR_aws_profile=ghilbut-tofu-apply-for-ultary-domains
verify_root ghilbut-tofu-apply-for-ultary-domains ultary/domains/tofu
unset TF_VAR_aws_profile
unset TF_VAR_ghilbut_dkim_for_root_domain
```

`tofu plan -detailed-exitcode`의 성공 결과는 exit code `0`이다. K3s plan에는 `cpa`
Kubernetes API 연결이 필요하다.

## CDN verification

GitHub Actions role ARN repository variable을 설정하고 확인한다.

```sh
gh variable set AWS_IAM_ROLE_CDN_GITHUB_ACTIONS_ARN \
  --repo ghilbut/platform \
  --body 'arn:aws:iam::012646747332:role/cdn-platform-github-actions'

gh api repos/ghilbut/platform/actions/variables/AWS_IAM_ROLE_CDN_GITHUB_ACTIONS_ARN
```

CloudFront와 공개 CPA OIDC document를 확인한다.

```sh
AWS_PROFILE=ghilbut-tofu-apply-for-workloads \
  aws cloudfront get-distribution \
    --id E1T2QAKDOSQYWI \
    --query 'Distribution.{Status:Status,Aliases:DistributionConfig.Aliases.Items,DomainName:DomainName}'

curl --fail --silent --show-error \
  'https://oidc.k3s.ghilbut.com/cpa/.well-known/openid-configuration' \
  | jq -e \
      '.issuer == "https://oidc.k3s.ghilbut.com/cpa" and
       .jwks_uri == "https://oidc.k3s.ghilbut.com/cpa/openid/v1/jwks"'

curl --fail --silent --show-error \
  'https://oidc.k3s.ghilbut.com/cpa/openid/v1/jwks' \
  | jq -e '.keys | length > 0'
```
