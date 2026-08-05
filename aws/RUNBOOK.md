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

열 개 source profile을 같은 session에 연결한다.

```sh
aws configure set sso_session ghilbut --profile ghilbut-foundation-management
aws configure set sso_account_id 384959722788 --profile ghilbut-foundation-management
aws configure set sso_role_name FoundationManagement --profile ghilbut-foundation-management
aws configure set region us-east-1 --profile ghilbut-foundation-management

aws configure set sso_session ghilbut --profile ghilbut-billing
aws configure set sso_account_id 384959722788 --profile ghilbut-billing
aws configure set sso_role_name Billing --profile ghilbut-billing
aws configure set region us-east-1 --profile ghilbut-billing

aws configure set sso_session ghilbut --profile ghilbut-tofu-plan-for-management
aws configure set sso_account_id 384959722788 --profile ghilbut-tofu-plan-for-management
aws configure set sso_role_name TofuPlanForManagement --profile ghilbut-tofu-plan-for-management
aws configure set region us-east-1 --profile ghilbut-tofu-plan-for-management

aws configure set sso_session ghilbut --profile ghilbut-tofu-apply-for-management
aws configure set sso_account_id 384959722788 --profile ghilbut-tofu-apply-for-management
aws configure set sso_role_name TofuApplyForManagement --profile ghilbut-tofu-apply-for-management
aws configure set region us-east-1 --profile ghilbut-tofu-apply-for-management

aws configure set sso_session ghilbut --profile ghilbut-tofu-plan-for-workloads
aws configure set sso_account_id 012646747332 --profile ghilbut-tofu-plan-for-workloads
aws configure set sso_role_name TofuPlanForWorkloads --profile ghilbut-tofu-plan-for-workloads
aws configure set region us-east-1 --profile ghilbut-tofu-plan-for-workloads

aws configure set sso_session ghilbut --profile ghilbut-tofu-apply-for-workloads
aws configure set sso_account_id 012646747332 --profile ghilbut-tofu-apply-for-workloads
aws configure set sso_role_name TofuApplyForWorkloads --profile ghilbut-tofu-apply-for-workloads
aws configure set region us-east-1 --profile ghilbut-tofu-apply-for-workloads

aws configure set sso_session ghilbut --profile ghilbut-tofu-plan-for-domains
aws configure set sso_account_id 869061964712 --profile ghilbut-tofu-plan-for-domains
aws configure set sso_role_name TofuPlanForDomains --profile ghilbut-tofu-plan-for-domains
aws configure set region us-east-1 --profile ghilbut-tofu-plan-for-domains

aws configure set sso_session ghilbut --profile ghilbut-tofu-apply-for-domains
aws configure set sso_account_id 869061964712 --profile ghilbut-tofu-apply-for-domains
aws configure set sso_role_name TofuApplyForDomains --profile ghilbut-tofu-apply-for-domains
aws configure set region us-east-1 --profile ghilbut-tofu-apply-for-domains

aws configure set sso_session ghilbut --profile ghilbut-tofu-plan-for-ultary-domains
aws configure set sso_account_id 971119963968 --profile ghilbut-tofu-plan-for-ultary-domains
aws configure set sso_role_name TofuPlanForUltaryDomains --profile ghilbut-tofu-plan-for-ultary-domains
aws configure set region us-east-1 --profile ghilbut-tofu-plan-for-ultary-domains

aws configure set sso_session ghilbut --profile ghilbut-tofu-apply-for-ultary-domains
aws configure set sso_account_id 971119963968 --profile ghilbut-tofu-apply-for-ultary-domains
aws configure set sso_role_name TofuApplyForUltaryDomains --profile ghilbut-tofu-apply-for-ultary-domains
aws configure set region us-east-1 --profile ghilbut-tofu-apply-for-ultary-domains

aws configure set source_profile ghilbut-billing --profile ghilbut-billing-role
aws configure set role_arn arn:aws:iam::384959722788:role/billing \
  --profile ghilbut-billing-role
aws configure set role_session_name ghilbut-billing --profile ghilbut-billing-role
aws configure set region us-east-1 --profile ghilbut-billing-role
```

로그인하고 계정 ID를 확인한다.

```sh
export AWS_SDK_LOAD_CONFIG=1

aws sso login --profile ghilbut-foundation-management
aws sso login --profile ghilbut-billing
aws sso login --profile ghilbut-tofu-plan-for-management
aws sso login --profile ghilbut-tofu-apply-for-management
aws sso login --profile ghilbut-tofu-plan-for-workloads
aws sso login --profile ghilbut-tofu-apply-for-workloads
aws sso login --profile ghilbut-tofu-plan-for-domains
aws sso login --profile ghilbut-tofu-apply-for-domains
aws sso login --profile ghilbut-tofu-plan-for-ultary-domains
aws sso login --profile ghilbut-tofu-apply-for-ultary-domains

aws sts get-caller-identity --profile ghilbut-foundation-management \
  --query Account --output text
aws sts get-caller-identity --profile ghilbut-billing \
  --query Account --output text
aws sts get-caller-identity --profile ghilbut-tofu-plan-for-management \
  --query Account --output text
aws sts get-caller-identity --profile ghilbut-tofu-apply-for-management \
  --query Account --output text
aws sts get-caller-identity --profile ghilbut-tofu-plan-for-workloads \
  --query Account --output text
aws sts get-caller-identity --profile ghilbut-tofu-apply-for-workloads \
  --query Account --output text
aws sts get-caller-identity --profile ghilbut-tofu-plan-for-domains \
  --query Account --output text
aws sts get-caller-identity --profile ghilbut-tofu-apply-for-domains \
  --query Account --output text
aws sts get-caller-identity --profile ghilbut-tofu-plan-for-ultary-domains \
  --query Account --output text
aws sts get-caller-identity --profile ghilbut-tofu-apply-for-ultary-domains \
  --query Account --output text
```

FoundationManagement, Billing, Management Plan과 Management Apply 결과는 `384959722788`이다.
Workloads Plan과 Apply는 `012646747332`, Domains Plan과 Apply는 `869061964712`, UltaryDomains
Plan과 Apply는 `971119963968`이다.

## Execution order

| 순서 | Root | Profile | Provider access | 선행 조건 |
|---:|---|---|---|---|
| 1 | `aws/foundation/organizations/tofu/` | Management | Management `tofu-apply` | 없음 |
| 2 | `aws/foundation/accounts/tofu/` | Management | Management `tofu-apply` | organizations state |
| 3 | `aws/foundation/identity/tofu/` | Management | Management `tofu-apply` | accounts state |
| 4 | `aws/shared-services/tofu/` | Workloads | direct source와 SharedServices `tofu-apply` | SharedServices의 `TofuApplyForWorkloads` assignment |
| 5 | `github/tofu/` | Workloads | SharedServices `tofu-apply` | SharedServices role |
| 6 | `aws/cdn/tofu/` | Workloads | SharedServices `tofu-apply` | GitHub OIDC provider |
| 7 | `k3s/tofu/` | Workloads | direct source | CDN origin bucket와 `cpa` Kubernetes API |
| 8 | `domains/tofu/` | Domains | Domains `tofu-apply` | CDN state |
| 9 | `apps/tofu/` | Workloads | direct source | SharedServices의 `TofuApplyForWorkloads` assignment |
| 10 | `ultary/domains/tofu/` | UltaryDomains | direct source | UltaryDomains assignment |

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
  aws/foundation/organizations/tofu /tmp/aws-foundation-organizations.tfplan
apply_root ghilbut-tofu-apply-for-management \
  aws/foundation/accounts/tofu /tmp/aws-foundation-accounts.tfplan
apply_root ghilbut-tofu-apply-for-management \
  aws/foundation/identity/tofu /tmp/aws-foundation-identity.tfplan
apply_root ghilbut-tofu-apply-for-workloads \
  aws/shared-services/tofu /tmp/aws-shared-services.tfplan
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

## AWS Organizations verification

`SERVICE_CONTROL_POLICY`를 비활성화하지 않는다. 비활성화하면 Root, OU와 account의 모든
SCP 연결이 삭제되고 자동으로 복구되지 않는다.

```sh
AWS_PROFILE=ghilbut-tofu-apply-for-management AWS_SDK_LOAD_CONFIG=1 \
  aws organizations list-roots \
    --query 'Roots[?Id==`r-k1tk`].PolicyTypes' --output json

AWS_PROFILE=ghilbut-tofu-apply-for-management AWS_SDK_LOAD_CONFIG=1 \
  aws organizations list-policies-for-target \
    --target-id r-k1tk --filter SERVICE_CONTROL_POLICY \
    --query 'Policies[].Name' --output json

AWS_PROFILE=ghilbut-tofu-apply-for-management AWS_SDK_LOAD_CONFIG=1 \
  aws organizations list-policies-for-target \
    --target-id ou-k1tk-nmjtvc69 --filter SERVICE_CONTROL_POLICY \
    --query 'Policies[].Name' --output json

AWS_PROFILE=ghilbut-tofu-apply-for-management AWS_SDK_LOAD_CONFIG=1 \
  aws organizations list-accounts-for-parent \
    --parent-id r-k1tk --query 'Accounts[].Name' --output json

AWS_PROFILE=ghilbut-tofu-apply-for-management AWS_SDK_LOAD_CONFIG=1 \
  aws organizations list-accounts-for-parent \
    --parent-id ou-k1tk-nmjtvc69 --query 'Accounts[].Name' --output json

for account_id in 384959722788 012646747332 869061964712 971119963968; do
  AWS_PROFILE=ghilbut-tofu-apply-for-management AWS_SDK_LOAD_CONFIG=1 \
    aws organizations list-policies-for-target \
      --target-id "$account_id" --filter SERVICE_CONTROL_POLICY \
      --query 'Policies[].Name' --output json
done
```

결과는 다음 상태와 일치해야 한다.

- Root policy type: `SERVICE_CONTROL_POLICY`, `ENABLED`
- Root SCP: `FullAWSAccess`, `ProtectMemberAccounts`
- Infrastructure OU SCP: `FullAWSAccess`
- 각 account의 직접 연결 SCP: `FullAWSAccess`
- Root account: Management, UltaryDomains
- Infrastructure OU account: Domains, SharedServices

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
  --profile ghilbut-billing \
  --role-arn arn:aws:iam::384959722788:role/billing \
  --role-session-name verify-management-billing \
  --query 'AssumedRoleUser.Arn' --output text

aws sts assume-role \
  --profile ghilbut-tofu-plan-for-management \
  --role-arn arn:aws:iam::384959722788:role/tofu-plan \
  --role-session-name verify-management-tofu-plan \
  --query 'AssumedRoleUser.Arn' --output text

aws sts assume-role \
  --profile ghilbut-tofu-apply-for-management \
  --role-arn arn:aws:iam::384959722788:role/tofu-apply \
  --role-session-name verify-management-tofu-apply \
  --query 'AssumedRoleUser.Arn' --output text

aws sts assume-role \
  --profile ghilbut-tofu-plan-for-workloads \
  --role-arn arn:aws:iam::012646747332:role/tofu-plan \
  --role-session-name verify-shared-services-tofu-plan \
  --query 'AssumedRoleUser.Arn' --output text

aws sts assume-role \
  --profile ghilbut-tofu-apply-for-workloads \
  --role-arn arn:aws:iam::012646747332:role/tofu-apply \
  --role-session-name verify-shared-services-tofu-apply \
  --query 'AssumedRoleUser.Arn' --output text

aws sts assume-role \
  --profile ghilbut-tofu-plan-for-domains \
  --role-arn arn:aws:iam::869061964712:role/tofu-plan \
  --role-session-name verify-domains-tofu-plan \
  --query 'AssumedRoleUser.Arn' --output text

aws sts assume-role \
  --profile ghilbut-tofu-apply-for-domains \
  --role-arn arn:aws:iam::869061964712:role/tofu-apply \
  --role-session-name verify-domains-tofu-apply \
  --query 'AssumedRoleUser.Arn' --output text
```

Plan source identity에서 해당 `tofu-apply` role 수임이 거부되는지 확인한다.

```sh
if aws sts assume-role \
  --profile ghilbut-tofu-plan-for-management \
  --role-arn arn:aws:iam::384959722788:role/tofu-apply \
  --role-session-name reject-management-tofu-apply; then
  exit 1
fi

if aws sts assume-role \
  --profile ghilbut-tofu-plan-for-workloads \
  --role-arn arn:aws:iam::012646747332:role/tofu-apply \
  --role-session-name reject-shared-services-tofu-apply; then
  exit 1
fi

if aws sts assume-role \
  --profile ghilbut-tofu-plan-for-domains \
  --role-arn arn:aws:iam::869061964712:role/tofu-apply \
  --role-session-name reject-domains-tofu-apply; then
  exit 1
fi
```

세 명령은 `AccessDenied`를 반환해야 한다. Plan permission set session duration과 `tofu-plan`
role의 configured maximum session duration은 4시간이다. IAM role chaining을 사용하는
`tofu-plan` session은 최대 1시간이다.

### Domains execution role bootstrap

Domains `tofu-apply`가 `tofu-plan` 관리 권한을 갖지 않은 상태에서 두 resource를 함께 추가하면
apply가 실패한다. Management `tofu-apply`에서 Domains `OrganizationAccountAccessRole`을 수임하여
계획한 `tofu-apply` inline policy를 먼저 적용한다.

```sh
aws configure set source_profile ghilbut-tofu-apply-for-management \
  --profile ghilbut-management-bootstrap
aws configure set role_arn arn:aws:iam::384959722788:role/tofu-apply \
  --profile ghilbut-management-bootstrap
aws configure set role_session_name ghilbut-management-bootstrap \
  --profile ghilbut-management-bootstrap
aws configure set region us-east-1 --profile ghilbut-management-bootstrap

aws configure set source_profile ghilbut-management-bootstrap \
  --profile ghilbut-domains-bootstrap
aws configure set role_arn \
  arn:aws:iam::869061964712:role/OrganizationAccountAccessRole \
  --profile ghilbut-domains-bootstrap
aws configure set role_session_name ghilbut-domains-bootstrap \
  --profile ghilbut-domains-bootstrap
aws configure set region us-east-1 --profile ghilbut-domains-bootstrap

export TF_VAR_ghilbut_dkim_for_root_domain="$(
  AWS_PROFILE=ghilbut-tofu-apply-for-domains AWS_SDK_LOAD_CONFIG=1 \
    tofu -chdir=domains/tofu state pull \
    | jq -r '
        .resources[]
        | select(.type == "aws_route53_record" and .name == "google_dkim")
        | .instances[0].attributes.records[0]
      '
)"

AWS_PROFILE=ghilbut-tofu-apply-for-domains AWS_SDK_LOAD_CONFIG=1 \
  tofu -chdir=domains/tofu plan \
    -out=/tmp/aws-domains-bootstrap.tfplan

domains_apply_policy="$(
  tofu -chdir=domains/tofu show -json /tmp/aws-domains-bootstrap.tfplan \
    | jq -c -r '
        .resource_changes[]
        | select(.address == "aws_iam_role_policy.tofu_apply")
        | .change.after.policy
      '
)"

AWS_PROFILE=ghilbut-domains-bootstrap AWS_SDK_LOAD_CONFIG=1 \
  aws iam put-role-policy \
    --role-name tofu-apply \
    --policy-name tofu-apply-inline \
    --policy-document "$domains_apply_policy"

unset domains_apply_policy
unset TF_VAR_ghilbut_dkim_for_root_domain
```

bootstrap 후 Domains saved plan을 다시 만든다. 새 plan에서 `aws_iam_role_policy.tofu_apply`는
변경이 없어야 하며 `tofu-plan` role과 inline policy만 생성해야 한다.
`OrganizationAccountAccessRole`은 Domains account 전체 관리자 권한을 갖는다. 이 절차의
SSO → Management `tofu-apply` → Domains `OrganizationAccountAccessRole` chaining session은 최대
1시간이며 `--duration-seconds`에 3600보다 큰 값을 지정하지 않는다.

## Billing activation and verification

Management root user가 account별 Billing Console 접근 설정을 한 번 활성화한다.

1. Management root user로 AWS Management Console에 로그인한다.
2. [Account](https://console.aws.amazon.com/billing/home?#/account)를 연다.
3. `IAM user and role access to Billing information`에서 `Edit`를 선택한다.
4. `Activate IAM access`를 선택한다.
5. `Update`를 선택한다.

이 설정은 OpenTofu로 관리하지 않는다. AWS는 root user가 Billing Console에서 변경하는 절차를
안내한다. Cost Explorer API는 이 설정의 적용 대상이 아니므로 다음 조회는 IAM policy와 API
접근만 검증한다.

```sh
aws ce get-cost-and-usage \
  --profile ghilbut-billing \
  --region us-east-1 \
  --time-period Start=2026-08-01,End=2026-09-01 \
  --granularity MONTHLY \
  --metrics UnblendedCost \
  --query 'length(ResultsByTime)' --output text

aws ce get-cost-and-usage \
  --profile ghilbut-billing-role \
  --region us-east-1 \
  --time-period Start=2026-08-01,End=2026-09-01 \
  --granularity MONTHLY \
  --metrics UnblendedCost \
  --query 'length(ResultsByTime)' --output text
```

두 결과는 모두 `1`이다.

Billing Console 접근을 별도로 검증한다.

1. [AWS access portal](https://ghilbut.awsapps.com/start)을 연다.
2. Management account `384959722788`의 `Billing` permission set으로 Console을 연다.
3. Billing Home, Bills와 Cost Explorer를 각각 열고 내용이 표시되는지 확인한다.

`Billing` permission set의 session duration은 4시간이다. `ghilbut-billing-role`은 IAM role
chaining을 사용하므로 `billing` role session은 최대 1시간이다.

## State verification

Plan source identity가 해당 state를 읽는지 확인한다. `head-object`는 state 내용을 출력하지
않는다.

```sh
verify_plan_state_read() {
  profile_name="$1"
  state_key="$2"

  AWS_PROFILE="$profile_name" AWS_SDK_LOAD_CONFIG=1 \
    aws s3api head-object \
      --bucket ghilbut-tfstates \
      --key "$state_key" \
      --query '{Length:ContentLength,Version:VersionId}'
}

verify_plan_state_read ghilbut-tofu-plan-for-management \
  platform/aws/foundation/accounts.tfstate
verify_plan_state_read ghilbut-tofu-plan-for-management \
  platform/aws/foundation/identity.tfstate
verify_plan_state_read ghilbut-tofu-plan-for-management \
  platform/aws/foundation/organizations.tfstate
verify_plan_state_read ghilbut-tofu-plan-for-workloads k3s.tfstate
verify_plan_state_read ghilbut-tofu-plan-for-workloads platform/apps.tfstate
verify_plan_state_read ghilbut-tofu-plan-for-workloads platform/aws/cdn.tfstate
verify_plan_state_read ghilbut-tofu-plan-for-workloads platform/aws/shared-services.tfstate
verify_plan_state_read ghilbut-tofu-plan-for-workloads platform/github.tfstate
verify_plan_state_read ghilbut-tofu-plan-for-domains platform/domains.tfstate
verify_plan_state_read ghilbut-tofu-plan-for-ultary-domains ultary/domains.tfstate
```

Plan source policy에서 `s3:PutObject`와 `s3:DeleteObject` resource는 해당 `.tflock` ARN만
포함한다. 실제 `.tfstate` object에 쓰기 요청을 보내지 않는다. Plan의 lock 생성과 제거는
provider가 `tofu-plan`을 선택하고 backend의 고정 profile이 제거된 root에서 OpenTofu plan을
실행하여 확인한다.

다음 명령은 active state object만 출력한다. 결과는
[[aws/README#State ownership|State ownership]] 표의 열 개 key와 일치해야 한다.

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

verify_root ghilbut-tofu-apply-for-management aws/foundation/organizations/tofu
verify_root ghilbut-tofu-apply-for-management aws/foundation/accounts/tofu
verify_root ghilbut-tofu-apply-for-management aws/foundation/identity/tofu
verify_root ghilbut-tofu-apply-for-workloads aws/shared-services/tofu
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
