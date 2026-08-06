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

열두 개 source profile을 같은 session에 연결한다.

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

aws configure set sso_session ghilbut --profile ghilbut-tofu-plan-for-security-tooling
aws configure set sso_account_id 954066442429 --profile ghilbut-tofu-plan-for-security-tooling
aws configure set sso_role_name TofuPlanForWorkloads --profile ghilbut-tofu-plan-for-security-tooling
aws configure set region us-east-1 --profile ghilbut-tofu-plan-for-security-tooling

aws configure set sso_session ghilbut --profile ghilbut-tofu-apply-for-security-tooling
aws configure set sso_account_id 954066442429 --profile ghilbut-tofu-apply-for-security-tooling
aws configure set sso_role_name TofuApplyForWorkloads --profile ghilbut-tofu-apply-for-security-tooling
aws configure set region us-east-1 --profile ghilbut-tofu-apply-for-security-tooling

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
aws sso login --profile ghilbut-tofu-plan-for-security-tooling
aws sso login --profile ghilbut-tofu-apply-for-security-tooling
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
aws sts get-caller-identity --profile ghilbut-tofu-plan-for-security-tooling \
  --query Account --output text
aws sts get-caller-identity --profile ghilbut-tofu-apply-for-security-tooling \
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
Plan과 Apply는 `971119963968`이다. SecurityTooling Plan과 Apply는 `954066442429`이다.

## Execution order

| 순서 | Root | Apply profile | Apply provider access | 선행 조건 |
|---:|---|---|---|---|
| 1 | `aws/foundation/organizations/tofu/` | `ghilbut-tofu-apply-for-management` | Management `tofu-apply` | 없음 |
| 2 | `aws/foundation/accounts/tofu/` | `ghilbut-tofu-apply-for-management` | Management `tofu-apply` | organizations state |
| 3 | `aws/foundation/identity/tofu/` | `ghilbut-tofu-apply-for-management` | Management `tofu-apply` | accounts state |
| 4 | `aws/shared-services/tofu/` | `ghilbut-tofu-apply-for-workloads` | SharedServices `tofu-apply` | SharedServices의 `TofuApplyForWorkloads` assignment |
| 5 | `aws/security-tooling/tofu/` | `ghilbut-tofu-apply-for-security-tooling` | SecurityTooling `tofu-apply` | SecurityTooling의 Workloads assignment와 중앙 state role |
| 6 | `aws/cdn/tofu/` | `ghilbut-tofu-apply-for-workloads` | SharedServices `tofu-apply` | GitHub OIDC provider |
| 7 | `k3s/tofu/` | `ghilbut-tofu-apply-for-workloads` | SharedServices `tofu-apply` | CDN origin bucket와 `cpa` Kubernetes API |
| 8 | `domains/tofu/` | `ghilbut-tofu-apply-for-domains` | Domains `tofu-apply` | CDN state |
| 9 | `apps/tofu/` | `ghilbut-tofu-apply-for-workloads` | SharedServices `tofu-apply` | SharedServices의 Workloads assignment |
| 10 | `ultary/domains/tofu/` | `ghilbut-tofu-apply-for-ultary-domains` | direct source | UltaryDomains assignment |

## Plan and apply

### Credential mode

Override가 없는 checkout은 Plan mode다. `AWS_PROFILE`에 대응하는 `TofuPlanFor*` source profile을
지정하면 backend는 SharedServices `tofu-state-readonly`를 수임하고 provider는 기본 `tofu-plan`
role을 수임한다. UltaryDomains provider는 source identity를 직접 사용한다.

Apply 전용 로컬 작업 공간은 다음 열 root에 `tofu-apply.auto.tfvars`를 둔다.

- `aws/foundation/organizations/tofu/`
- `aws/foundation/accounts/tofu/`
- `aws/foundation/identity/tofu/`
- `aws/shared-services/tofu/`
- `aws/security-tooling/tofu/`
- `aws/cdn/tofu/`
- `k3s/tofu/`
- `domains/tofu/`
- `apps/tofu/`

Management root 세 곳의 파일은 다음 값을 사용한다.

```hcl
aws_execution_role_arn = "arn:aws:iam::384959722788:role/tofu-apply"
```

SharedServices root 다섯 곳의 파일은 다음 값을 사용한다.

```hcl
aws_execution_role_arn = "arn:aws:iam::012646747332:role/tofu-apply"
```

Domains root의 파일은 다음 값을 사용한다.

```hcl
aws_execution_role_arn = "arn:aws:iam::869061964712:role/tofu-apply"
```

SecurityTooling root의 파일은 다음 값을 사용한다.

```hcl
aws_execution_role_arn = "arn:aws:iam::954066442429:role/tofu-apply"
```

모든 열 root의 Apply backend는 git에서 제외한 `tofu-state-apply.tfbackend`를 둔다.

```hcl
assume_role = {
  role_arn = "arn:aws:iam::012646747332:role/tofu-state-apply"
}
```

Apply mode에서는 대응하는 `TofuApplyFor*` source profile을 `AWS_PROFILE`에 지정한다. 자동 variable
file은 plan에도 적용되므로 Plan source profile과 함께 사용하지 않는다. `tofu-apply.auto.tfvars`와
`TF_VAR_aws_execution_role_arn`을 함께 사용하지 않는다. UltaryDomains는 override file 없이 Plan
또는 Apply source profile을 provider에 직접 사용한다.

Plan mode로 전환할 때는 backend 기본값인 `tofu-state-readonly`로 다시 초기화한다.

```sh
AWS_PROFILE='<plan-source-profile>' AWS_SDK_LOAD_CONFIG=1 \
  tofu -chdir='<root-path>' init -reconfigure
```

Apply mode로 전환할 때는 로컬 backend 설정으로 다시 초기화한다.

```sh
AWS_PROFILE='<apply-source-profile>' AWS_SDK_LOAD_CONFIG=1 \
  tofu -chdir='<root-path>' init -reconfigure \
    -backend-config=tofu-state-apply.tfbackend
```

Backend override는 `init` 결과에 저장된다. Source profile 또는 실행 mode를 바꿀 때마다
`init -reconfigure`를 실행한다.

새 account에서 `tofu-plan`과 `tofu-apply` role을 처음 생성할 때만 source identity를 provider에
직접 사용한다.

```hcl
# bootstrap.tfvars
aws_execution_role_arn = null
```

```sh
AWS_PROFILE='<apply-source-profile>' AWS_SDK_LOAD_CONFIG=1 \
  tofu -chdir='<role-owner-root>' init -reconfigure \
    -backend-config=tofu-state-apply.tfbackend

AWS_PROFILE='<apply-source-profile>' AWS_SDK_LOAD_CONFIG=1 \
  tofu -chdir='<role-owner-root>' plan \
    -var-file=bootstrap.tfvars \
    -out=/tmp/bootstrap-execution-roles.tfplan

AWS_PROFILE='<apply-source-profile>' AWS_SDK_LOAD_CONFIG=1 \
  tofu -chdir='<role-owner-root>' apply \
    /tmp/bootstrap-execution-roles.tfplan
```

두 execution role이 생성되면 `null`을 제거하고 기본 Plan 또는 로컬 Apply mode를 사용한다.
기존 account에서는 `null`을 사용하지 않는다.

### Required variables

UltaryDomains는 다음 필수 variable을 승인된 로컬 환경 변수나 git에서 제외한 variable file로
제공한다. Map variable의 환경 변수 값은 JSON object다.

- `ultary_co_dkim_for_root_domain`
- `ultary_co_txt_for_sub_domains`
- `ultary_co_cname_for_sub_domains`
- `ultary_co_dkim_for_sub_domains`

### Default plan

`tofu-apply.auto.tfvars`가 없는 checkout에서 다음 순서로 plan한다.

```sh
plan_root() {
  profile_name="$1"
  root_path="$2"

  AWS_PROFILE="$profile_name" AWS_SDK_LOAD_CONFIG=1 \
    tofu -chdir="$root_path" init -reconfigure
  AWS_PROFILE="$profile_name" AWS_SDK_LOAD_CONFIG=1 \
    tofu -chdir="$root_path" validate
  AWS_PROFILE="$profile_name" AWS_SDK_LOAD_CONFIG=1 \
    tofu -chdir="$root_path" plan -detailed-exitcode
}

plan_root ghilbut-tofu-plan-for-management aws/foundation/organizations/tofu
plan_root ghilbut-tofu-plan-for-management aws/foundation/accounts/tofu
plan_root ghilbut-tofu-plan-for-management aws/foundation/identity/tofu
plan_root ghilbut-tofu-plan-for-workloads aws/shared-services/tofu
plan_root ghilbut-tofu-plan-for-security-tooling aws/security-tooling/tofu
plan_root ghilbut-tofu-plan-for-workloads aws/cdn/tofu
plan_root ghilbut-tofu-plan-for-workloads k3s/tofu
plan_root ghilbut-tofu-plan-for-domains domains/tofu
plan_root ghilbut-tofu-plan-for-workloads apps/tofu
plan_root ghilbut-tofu-plan-for-ultary-domains ultary/domains/tofu
```

각 명령의 성공 결과는 exit code `0`이다. K3s plan에는 `cpa` Kubernetes API 연결이 필요하다.

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
    tofu -chdir="$root_path" init -reconfigure \
      -backend-config=tofu-state-apply.tfbackend
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
apply_root ghilbut-tofu-apply-for-security-tooling \
  aws/security-tooling/tofu /tmp/aws-security-tooling.tfplan
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

apply_root ghilbut-tofu-apply-for-ultary-domains \
  ultary/domains/tofu /tmp/ultary-domains.tfplan
```

### State administration bootstrap

State bucket 전용 root를 구성하기 전에 Foundation identity와 SharedServices를 순서대로 적용한다.
Foundation identity는 `TofuApplyForWorkloads`에 `tofu-state-admin` 수임 권한을 부여한다.
SharedServices는 역할을 만들고 `deployer`의 수임 권한과 예약 backend key 접근을 추가한다.

```sh
apply_root \
  ghilbut-tofu-apply-for-management \
  aws/foundation/identity/tofu \
  /tmp/foundation-identity-state-admin-bootstrap.tfplan

apply_root \
  ghilbut-tofu-apply-for-workloads \
  aws/shared-services/tofu \
  /tmp/shared-services-state-admin-bootstrap.tfplan
```

SharedServices plan에는 state bucket, bucket policy, public access block, 암호화와 versioning 변경이
없어야 한다. 적용 후 Workloads IAM Identity Center session을 새로 시작하고 아래 State verification을
실행한다.

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

security_ou_id="$(
  AWS_PROFILE=ghilbut-tofu-apply-for-management AWS_SDK_LOAD_CONFIG=1 \
    aws organizations list-organizational-units-for-parent \
      --parent-id r-k1tk \
      --query 'OrganizationalUnits[?Name==`Security`].Id | [0]' \
      --output text
)"
test "$security_ou_id" != "None"

AWS_PROFILE=ghilbut-tofu-apply-for-management AWS_SDK_LOAD_CONFIG=1 \
  aws organizations list-policies-for-target \
    --target-id "$security_ou_id" --filter SERVICE_CONTROL_POLICY \
    --query 'Policies[].Name' --output json

AWS_PROFILE=ghilbut-tofu-apply-for-management AWS_SDK_LOAD_CONFIG=1 \
  aws organizations list-accounts-for-parent \
    --parent-id r-k1tk --query 'Accounts[].Name' --output json

AWS_PROFILE=ghilbut-tofu-apply-for-management AWS_SDK_LOAD_CONFIG=1 \
  aws organizations list-accounts-for-parent \
    --parent-id ou-k1tk-nmjtvc69 --query 'Accounts[].Name' --output json

AWS_PROFILE=ghilbut-tofu-apply-for-management AWS_SDK_LOAD_CONFIG=1 \
  aws organizations list-accounts-for-parent \
    --parent-id "$security_ou_id" --query 'Accounts[].Name' --output json

for account_id in 384959722788 012646747332 869061964712 954066442429 971119963968; do
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
- Security OU SCP: `FullAWSAccess`
- 각 account의 직접 연결 SCP: `FullAWSAccess`
- Root account: Management, UltaryDomains
- Infrastructure OU account: Domains, SharedServices
- Security OU account: SecurityTooling

SecurityTooling account와 비활성 opt-in Region을 확인한다.

```sh
AWS_PROFILE=ghilbut-tofu-apply-for-management AWS_SDK_LOAD_CONFIG=1 \
  aws organizations describe-account \
    --account-id 954066442429 \
    --query 'Account.[Id,Name,Email,State,Paths[0]]' --output table

AWS_PROFILE=ghilbut-tofu-apply-for-management AWS_SDK_LOAD_CONFIG=1 \
  aws account list-regions \
    --account-id 954066442429 \
    --region-opt-status-contains DISABLED \
    --query 'Regions[].RegionName' --output table
```

계정 결과는 다음 값과 일치해야 한다.

- ID: `954066442429`
- Name: `SecurityTooling`
- Email: `aws-security-tooling@ghilbut.com`
- State: `ACTIVE`
- Path: `o-ncl6mypc8p/r-k1tk/ou-k1tk-rx2wvnws/954066442429/`

비활성 Region 결과는 다음 17개와 일치해야 한다.

- `af-south-1`
- `ap-east-1`
- `ap-east-2`
- `ap-south-2`
- `ap-southeast-3`
- `ap-southeast-4`
- `ap-southeast-5`
- `ap-southeast-6`
- `ap-southeast-7`
- `ca-west-1`
- `eu-central-2`
- `eu-south-1`
- `eu-south-2`
- `il-central-1`
- `me-central-1`
- `me-south-1`
- `mx-central-1`

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
  --profile ghilbut-tofu-plan-for-security-tooling \
  --role-arn arn:aws:iam::954066442429:role/tofu-plan \
  --role-session-name verify-security-tooling-tofu-plan \
  --query 'AssumedRoleUser.Arn' --output text

aws sts assume-role \
  --profile ghilbut-tofu-apply-for-security-tooling \
  --role-arn arn:aws:iam::954066442429:role/tofu-apply \
  --role-session-name verify-security-tooling-tofu-apply \
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

if aws sts assume-role \
  --profile ghilbut-tofu-plan-for-security-tooling \
  --role-arn arn:aws:iam::954066442429:role/tofu-apply \
  --role-session-name reject-security-tooling-tofu-apply; then
  exit 1
fi

if aws sts assume-role \
  --profile ghilbut-tofu-apply-for-security-tooling \
  --role-arn arn:aws:iam::954066442429:role/tofu-plan \
  --role-session-name reject-security-tooling-tofu-plan; then
  exit 1
fi

if aws sts assume-role \
  --profile ghilbut-tofu-apply-for-workloads \
  --role-arn arn:aws:iam::954066442429:role/tofu-apply \
  --role-session-name reject-shared-services-to-security-tooling; then
  exit 1
fi

if aws sts assume-role \
  --profile ghilbut-tofu-apply-for-security-tooling \
  --role-arn arn:aws:iam::012646747332:role/tofu-apply \
  --role-session-name reject-security-tooling-to-shared-services; then
  exit 1
fi
```

일곱 명령은 `AccessDenied`를 반환해야 한다. Plan permission set session duration과 `tofu-plan`
role의 configured maximum session duration은 4시간이다. IAM role chaining을 사용하는
`tofu-plan` session은 최대 1시간이다.

세 root의 중앙 관리 기능 거부 목록이 같은지 확인한다. 두 `diff` 명령은 출력 없이 종료되어야
한다.

```zsh
diff -u \
  <(sed -n '/central_administration_denied_actions = \[/,/^  \]$/p' \
    aws/foundation/identity/tofu/main.tf) \
  <(sed -n '/central_administration_denied_actions = \[/,/^  \]$/p' \
    aws/shared-services/tofu/main.tf)

diff -u \
  <(sed -n '/central_administration_denied_actions = \[/,/^  \]$/p' \
    aws/foundation/identity/tofu/main.tf) \
  <(sed -n '/central_administration_denied_actions = \[/,/^  \]$/p' \
    aws/security-tooling/tofu/main.tf)
```

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

`ce:DescribeReport`는 Cost Explorer 보고서 화면을 표시하는 읽기 권한이다. AWS 관리형
`job-function/Billing` policy와 별도로 `Billing` permission set과 `billing` role에 부여한다.
두 principal의 권한 결정을 확인한다.

```sh
billing_sso_role_arn="$(
  aws iam list-roles \
    --profile ghilbut-foundation-management \
    --query 'Roles[?starts_with(RoleName, `AWSReservedSSO_Billing_`)] | [0].Arn' \
    --output text
)"

aws iam simulate-principal-policy \
  --profile ghilbut-foundation-management \
  --policy-source-arn "$billing_sso_role_arn" \
  --action-names ce:DescribeReport \
  --query 'EvaluationResults[0].EvalDecision' \
  --output text

aws iam simulate-principal-policy \
  --profile ghilbut-foundation-management \
  --policy-source-arn arn:aws:iam::384959722788:role/billing \
  --action-names ce:DescribeReport \
  --query 'EvaluationResults[0].EvalDecision' \
  --output text
```

두 결과는 모두 `allowed`이다.

Billing Console 접근을 별도로 검증한다.

1. [AWS access portal](https://ghilbut.awsapps.com/start)을 연다.
2. Management account `384959722788`의 `Billing` permission set으로 Console을 연다.
3. Billing Home, Bills와 Cost Explorer를 각각 열고 내용이 표시되는지 확인한다.
4. Cost Explorer에 `ce:DescribeReport` 권한 오류가 표시되지 않는지 확인한다.

`Billing` permission set의 session duration은 4시간이다. `ghilbut-billing-role`은 IAM role
chaining을 사용하므로 `billing` role session은 최대 1시간이다.

## State verification

중앙 state role의 권한 결정을 확인한다. `.tfstate` 쓰기 요청은 실행하지 않는다.

```sh
simulate_state_role() {
  role_name="$1"

  AWS_PROFILE=ghilbut-tofu-apply-for-workloads AWS_SDK_LOAD_CONFIG=1 \
    aws iam simulate-principal-policy \
    --policy-source-arn "arn:aws:iam::012646747332:role/$role_name" \
    --action-names s3:GetObject s3:PutObject s3:DeleteObject \
    --resource-arns \
      arn:aws:s3:::ghilbut-tfstates/platform/aws/shared-services.tfstate \
      arn:aws:s3:::ghilbut-tfstates/platform/aws/shared-services.tfstate.tflock \
      arn:aws:s3:::ghilbut-tfstates/platform/aws/shared-services/state.tfstate \
      arn:aws:s3:::ghilbut-tfstates/platform/aws/shared-services/state.tfstate.tflock \
      arn:aws:s3:::ghilbut-tfstates/recovery/platform/aws/shared-services.tfstate \
      arn:aws:s3:::ghilbut-tfstates-v2/platform/aws/shared-services.tfstate \
    --output json \
  | jq -r '
      .EvaluationResults[]
      | .EvalActionName as $action
      | .ResourceSpecificResults[]
      | [$action, .EvalResourceName, .EvalResourceDecision]
      | @tsv
    '
}

simulate_state_role tofu-state-readonly
simulate_state_role tofu-state-apply
```

`tofu-state-readonly`는 기존 key와 예약 key의 `.tfstate`에 대한 `GetObject`, 두 `.tflock`에 대한
세 작업만 `allowed`다. `tofu-state-apply`는 두 key의 `.tfstate`와 `.tflock`에 대한 세 작업이 모두
`allowed`다. Recovery key와 `ghilbut-tfstates-v2` 결과는 모두 `implicitDeny`다. Plan의 lock 생성과
제거는 기본 Plan backend로 OpenTofu plan을 실행하여 확인한다.

State bucket 관리 역할의 trust와 권한을 확인한다.

```zsh
state_admin_role_arn='arn:aws:iam::012646747332:role/tofu-state-admin'

AWS_PROFILE=ghilbut-tofu-apply-for-workloads AWS_SDK_LOAD_CONFIG=1 \
  aws sts assume-role \
    --role-arn "$state_admin_role_arn" \
    --role-session-name verify-state-admin-apply-source \
    --query 'AssumedRoleUser.Arn' \
    --output text

if AWS_PROFILE=ghilbut-tofu-plan-for-workloads AWS_SDK_LOAD_CONFIG=1 \
  aws sts assume-role \
    --role-arn "$state_admin_role_arn" \
    --role-session-name verify-state-admin-plan-source \
    >/dev/null 2>&1; then
  echo 'Plan source assumed tofu-state-admin.' >&2
  exit 1
fi

simulation_credentials="$(
  AWS_PROFILE=ghilbut-tofu-apply-for-workloads AWS_SDK_LOAD_CONFIG=1 \
    aws sts assume-role \
      --role-arn arn:aws:iam::012646747332:role/tofu-apply \
      --role-session-name verify-state-admin-policy \
      --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
      --output text
)"
read -r access_key secret_key session_token <<< "$simulation_credentials"

env -u AWS_PROFILE \
  AWS_ACCESS_KEY_ID="$access_key" \
  AWS_SECRET_ACCESS_KEY="$secret_key" \
  AWS_SESSION_TOKEN="$session_token" \
  AWS_SDK_LOAD_CONFIG=0 \
  aws iam simulate-principal-policy \
    --policy-source-arn arn:aws:iam::012646747332:role/deployer \
    --action-names sts:AssumeRole \
    --resource-arns "$state_admin_role_arn" \
    --query 'EvaluationResults[0].EvalDecision' \
    --output text

env -u AWS_PROFILE \
  AWS_ACCESS_KEY_ID="$access_key" \
  AWS_SECRET_ACCESS_KEY="$secret_key" \
  AWS_SESSION_TOKEN="$session_token" \
  AWS_SDK_LOAD_CONFIG=0 \
  aws iam simulate-principal-policy \
    --policy-source-arn "$state_admin_role_arn" \
    --action-names \
      s3:GetBucketPolicy \
      s3:PutBucketPolicy \
      s3:PutLifecycleConfiguration \
      s3:PutBucketVersioning \
      s3:PutReplicationConfiguration \
      s3:DeleteBucket \
    --resource-arns arn:aws:s3:::ghilbut-tfstates \
    --output json \
  | jq -r '
      .EvaluationResults[]
      | .EvalActionName as $action
      | .ResourceSpecificResults[]
      | [$action, .EvalResourceName, .EvalResourceDecision]
      | @tsv
    '

env -u AWS_PROFILE \
  AWS_ACCESS_KEY_ID="$access_key" \
  AWS_SECRET_ACCESS_KEY="$secret_key" \
  AWS_SESSION_TOKEN="$session_token" \
  AWS_SDK_LOAD_CONFIG=0 \
  aws iam simulate-principal-policy \
    --policy-source-arn "$state_admin_role_arn" \
    --action-names s3:GetObject s3:PutObject s3:DeleteObject \
    --resource-arns \
      arn:aws:s3:::ghilbut-tfstates/platform/aws/shared-services.tfstate \
    --output json \
  | jq -r '
      .EvaluationResults[]
      | .EvalActionName as $action
      | .ResourceSpecificResults[]
      | [$action, .EvalResourceName, .EvalResourceDecision]
      | @tsv
    '

unset simulation_credentials access_key secret_key session_token
```

Apply source의 `AssumedRoleUser.Arn`이 출력되고 Plan source 수임은 실패해야 한다. `deployer`의
`sts:AssumeRole` simulation은 `allowed`다. Lifecycle을 포함한 bucket 설정 작업은 `allowed`,
`s3:DeleteBucket`은 `explicitDeny`, state object 세 작업은 `implicitDeny`다.

Workload Apply provider role의 state 객체 권한 결정을 확인한다.

```zsh
simulate_workload_apply_state() {
  source_profile="$1"
  account_id="$2"
  credentials="$(
    AWS_PROFILE="$source_profile" AWS_SDK_LOAD_CONFIG=1 \
      aws sts assume-role \
      --role-arn "arn:aws:iam::$account_id:role/tofu-apply" \
      --role-session-name verify-state-object-deny \
      --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
      --output text
  )"
  read -r access_key secret_key session_token <<< "$credentials"

  env -u AWS_PROFILE \
    AWS_ACCESS_KEY_ID="$access_key" \
    AWS_SECRET_ACCESS_KEY="$secret_key" \
    AWS_SESSION_TOKEN="$session_token" \
    AWS_SDK_LOAD_CONFIG=0 \
    aws iam simulate-principal-policy \
    --policy-source-arn "arn:aws:iam::$account_id:role/tofu-apply" \
    --action-names \
      s3:AbortMultipartUpload \
      s3:DeleteObject \
      s3:GetObject \
      s3:ListMultipartUploadParts \
      s3:PutObject \
      s3:RestoreObject \
    --resource-arns \
      arn:aws:s3:::ghilbut-tfstates/platform/aws/shared-services.tfstate \
      arn:aws:s3:::ghilbut-tfstates-v2/platform/aws/shared-services.tfstate \
    --output json \
  | jq -r '
      .EvaluationResults[]
      | .EvalActionName as $action
      | .ResourceSpecificResults[]
      | [$action, .EvalResourceName, .EvalResourceDecision]
      | @tsv
    '

  env -u AWS_PROFILE \
    AWS_ACCESS_KEY_ID="$access_key" \
    AWS_SECRET_ACCESS_KEY="$secret_key" \
    AWS_SESSION_TOKEN="$session_token" \
    AWS_SDK_LOAD_CONFIG=0 \
    aws iam simulate-principal-policy \
    --policy-source-arn "arn:aws:iam::$account_id:role/tofu-apply" \
    --action-names s3:PutLifecycleConfiguration \
    --resource-arns \
      arn:aws:s3:::ghilbut-tfstates \
      arn:aws:s3:::ghilbut-tfstates-v2 \
    --output json \
  | jq -r '
      .EvaluationResults[]
      | .EvalActionName as $action
      | .ResourceSpecificResults[]
      | [$action, .EvalResourceName, .EvalResourceDecision]
      | @tsv
    '
}

simulate_workload_apply_state \
  ghilbut-tofu-apply-for-workloads 012646747332
simulate_workload_apply_state \
  ghilbut-tofu-apply-for-security-tooling 954066442429
```

각 `simulate_workload_apply_state` 호출은 두 명령에서 열네 개 권한 결정을 출력한다. 두 호출에서
출력하는 스물여덟 개 권한 결정은 모두 `explicitDeny`다.

다음 명령은 `tofu-state-readonly`가 읽는 state object를 출력한다. 결과는
[[aws/README#State ownership|State ownership]] 표의 열 개 active key와 예약 key
`platform/aws/shared-services/state.tfstate`를 포함한 열한 개다.

```sh
AWS_PROFILE=ghilbut-tofu-apply-for-workloads AWS_SDK_LOAD_CONFIG=1 \
  aws iam get-role-policy \
    --role-name tofu-state-readonly \
    --policy-name tofu-state-readonly-inline \
    --query PolicyDocument --output json \
  | jq -r '
      .Statement[]
      | select(.Sid == "ReadStateObjects")
      | .Resource[]
      | sub("arn:aws:s3:::ghilbut-tfstates/"; "")
    '
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
verify_root ghilbut-tofu-apply-for-security-tooling aws/security-tooling/tofu
verify_root ghilbut-tofu-apply-for-workloads aws/cdn/tofu
verify_root ghilbut-tofu-apply-for-workloads k3s/tofu
verify_root ghilbut-tofu-apply-for-domains domains/tofu
verify_root ghilbut-tofu-apply-for-workloads apps/tofu

verify_root ghilbut-tofu-apply-for-ultary-domains ultary/domains/tofu
```

`tofu plan -detailed-exitcode`는 변경이 없으면 `0`, 변경이 있으면 `2`, 실패하면 `1`을 반환한다.
K3s plan에는 `cpa` Kubernetes API 연결이 필요하다.

## CI Plan verification

현재 CI 관리 root 전체와 두 Git revision 사이에서 변경된 root를 확인한다.

```sh
scripts/opentofu-plan-roots.sh all
scripts/opentofu-plan-roots.sh changed HEAD^ HEAD
scripts/opentofu-plan-roots.test.sh
```

목록은 다음 여덟 root를 순서대로 출력한다.

```text
aws/foundation/organizations/tofu
aws/foundation/accounts/tofu
aws/foundation/identity/tofu
aws/shared-services/tofu
aws/security-tooling/tofu
aws/cdn/tofu
domains/tofu
apps/tofu
```

`k3s/tofu/`는 `cpa` Kubernetes API와 로컬 `kubectl` context가 필요하므로 이 목록에 포함하지
않는다. `ultary/domains/tofu/`는 `deployer` 인가 범위 밖이며 필수 입력값을 별도로 관리하므로
포함하지 않는다.

공용 Plan 스크립트는 Apply provider override가 없는 작업 공간에서 실행한다. 로컬 실행은 root에
맞는 Plan source profile 하나를 선택한다.

```sh
AWS_PROFILE=ghilbut-tofu-plan-for-workloads AWS_SDK_LOAD_CONFIG=1 \
  scripts/opentofu-plan.sh aws/shared-services/tofu aws/cdn/tofu apps/tofu
```

수동 전체 Plan workflow를 `main`에서 실행하고 결과를 확인한다.

```sh
gh workflow run opentofu-plan.yml --ref main
gh run list --workflow opentofu-plan.yml --limit 1
gh run watch --repo ghilbut/platform
```

모든 root가 `OpenTofu Plan succeeded`를 출력하면 성공이다. 하나 이상의 root가 실패하면 workflow는
실패하고 마지막에 실패한 root를 모두 출력한다. 변경된 CI 관리 root가 없으면 AWS 자격 증명을
요청하지 않고 성공한다.

## CDN verification

공용 `deployer` role ARN repository variable을 설정하고 확인한다.

CDN 배포 role 전환은 다음 순서로 실행한다.

1. `aws/shared-services/tofu/`를 Apply하여 `deployer`와 대상 role trust를 적용한다.
2. `AWS_IAM_ROLE_DEPLOYER_ARN` repository variable을 설정한다.
3. `aws/cdn/tofu/`를 Apply하여 `cdn-platform-github-actions`를 제거한다.
4. CDN workflow를 실행하고 성공을 확인한다.

```sh
gh variable set AWS_IAM_ROLE_DEPLOYER_ARN \
  --repo ghilbut/platform \
  --body 'arn:aws:iam::012646747332:role/deployer'

gh api repos/ghilbut/platform/actions/variables/AWS_IAM_ROLE_DEPLOYER_ARN
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
