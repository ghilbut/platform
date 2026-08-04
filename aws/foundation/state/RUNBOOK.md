---
title: Platform state bucket migration runbook
type: runbook
area: aws-foundation
tags:
  - aws
  - opentofu
  - migration
---

# Platform state bucket migration runbook

이 Runbook은 OpenTofu backend를 Domains의 `ghilbut-tfstates`에서 Platform의
`ghilbut-tfstates-v2`로 이전한다. state는 S3 API로 복사하지 않는다. 모든 활성 root에서
`tofu init -migrate-state`를 실행한다.

섹션 1은 legacy bucket policy와 두 bucket IAM 권한만 포함한 bootstrap commit에서
실행한다. 섹션 2가 끝난 뒤 state root가 정확한 계정 ID를 사용하고 Platform bucket을
관리하며 모든 backend block이 v2를 가리키는 migration commit으로 전환한다. PR comment에
두 commit ID를 기록한다.

## 대상

| Root | State key | Migration profile |
|---|---|---|
| `aws/foundation/accounts/tofu/` | `platform/aws/foundation/accounts.tfstate` | `ghilbut-tofu-apply-for-management` |
| `aws/foundation/identity/tofu/` | `platform/aws/foundation/identity.tfstate` | `ghilbut-tofu-apply-for-management` |
| `aws/foundation/state/tofu/` | `platform/aws/foundation/state.tfstate` | `ghilbut-tofu-apply-for-workloads` |
| `aws/foundation/workload/tofu/` | `platform/aws/foundation/workload.tfstate` | `ghilbut-tofu-apply-for-workloads` |
| `aws/cdn/tofu/` | `platform/aws/cdn.tfstate` | `ghilbut-tofu-apply-for-workloads` |
| `domains/tofu/` | `platform/domains.tfstate` | `ghilbut-tofu-apply-for-domains` |
| `apps/tofu/` | `platform/apps.tfstate` | `ghilbut-tofu-apply-for-workloads-domains` |
| `github/tofu/` | `platform/github.tfstate` | `ghilbut-tofu-apply-for-workloads` |
| `k3s/tofu/` | `k3s.tfstate` | `ghilbut-tofu-apply-for-workloads` |
| `ultary/domains/tofu/` | `ultary/domains.tfstate` | `ghilbut-tofu-apply-for-ultary-domains` |

`platform/aws/accounts.tfstate`는 이전 대상에서 제외한다. 해당 state의 account ID가 활성
Foundation accounts state에 모두 포함되는지 확인한 뒤 기존 bucket과 함께 삭제한다.

## 1. 전환 권한 적용

Domains profile로 기존 bucket policy에 Platform state root 접근을 추가한다.

```sh
export AWS_SDK_LOAD_CONFIG=1
export AWS_PROFILE=ghilbut-tofu-apply-for-workloads-domains

tofu -chdir=aws/foundation/state/tofu init -reconfigure
tofu -chdir=aws/foundation/state/tofu plan
tofu -chdir=aws/foundation/state/tofu apply
```

Management profile로 Management, Domains, Platform, UltaryDomains의 source permission set에
두 bucket 접근 권한을 적용한다.

```sh
export AWS_PROFILE=ghilbut-tofu-apply-for-management

tofu -chdir=aws/foundation/identity/tofu init -reconfigure
tofu -chdir=aws/foundation/identity/tofu plan
tofu -chdir=aws/foundation/identity/tofu apply

aws sso-admin list-permission-set-provisioning-status \
  --instance-arn arn:aws:sso:::instance/ssoins-7223d00af1910289 \
  --max-results 20

aws configure set sso_session ghilbut --profile ghilbut-tofu-apply-for-domains
aws configure set sso_account_id 869061964712 --profile ghilbut-tofu-apply-for-domains
aws configure set sso_role_name TofuApplyForDomains --profile ghilbut-tofu-apply-for-domains
aws configure set region us-east-1 --profile ghilbut-tofu-apply-for-domains

aws configure set sso_session ghilbut --profile ghilbut-tofu-apply-for-ultary-domains
aws configure set sso_account_id 971119963968 --profile ghilbut-tofu-apply-for-ultary-domains
aws configure set sso_role_name TofuApplyForUltaryDomains --profile ghilbut-tofu-apply-for-ultary-domains
aws configure set region us-east-1 --profile ghilbut-tofu-apply-for-ultary-domains
```

## 2. 기존 bucket policy state 분리

기존 bucket policy는 모든 backend 이전이 끝날 때까지 AWS에 유지한다. state에서만 분리한다.

```sh
export AWS_PROFILE=ghilbut-tofu-apply-for-workloads-domains

tofu -chdir=aws/foundation/state/tofu state pull > /tmp/issue-97-state-before-detach.json
aws s3api list-object-versions --bucket ghilbut-tfstates \
  --prefix platform/aws/foundation/state.tfstate
tofu -chdir=aws/foundation/state/tofu state rm aws_s3_bucket_policy.foundation_state_access
aws s3api get-bucket-policy --bucket ghilbut-tfstates
```

기존 bucket의 versioned `platform/aws/foundation/state.tfstate`가 durable backup이다. migration
commit으로 전환하기 전에는 다음 명령으로 관리 상태를 복구할 수 있다.

```sh
tofu -chdir=aws/foundation/state/tofu import \
  aws_s3_bucket_policy.foundation_state_access ghilbut-tfstates
```

## 3. Platform bucket 생성

Migration commit의 state root는 accounts remote state를 읽지 않고 Management
`384959722788`, Domains `869061964712`, Platform `012646747332`, UltaryDomains
`971119963968` ID를 직접 사용한다. provider는 Platform `tofu-apply` 역할을 사용한다. 새
bucket이 생기기 전에는 backend block의 bucket 값만 명령행에서 기존 bucket으로 덮어쓴다.

```sh
export AWS_PROFILE=ghilbut-tofu-apply-for-workloads

tofu -chdir=aws/foundation/state/tofu init -reconfigure \
  -backend-config=bucket=ghilbut-tfstates
tofu -chdir=aws/foundation/state/tofu plan
tofu -chdir=aws/foundation/state/tofu apply

aws s3api get-bucket-versioning --bucket ghilbut-tfstates-v2
aws s3api get-public-access-block --bucket ghilbut-tfstates-v2
aws s3api get-bucket-encryption --bucket ghilbut-tfstates-v2
```

## 4. Backend 이전

각 root의 기존 lineage와 serial을 기록한 뒤 backend를 이전한다. 명령은 표의 profile로
실행한다.

```sh
tofu -chdir=<root> init -reconfigure \
  -backend-config=bucket=ghilbut-tfstates
tofu -chdir=<root> state pull | jq '{lineage, serial}'
tofu -chdir=<root> init -migrate-state -force-copy \
  -backend-config=bucket=ghilbut-tfstates-v2
tofu -chdir=<root> state pull | jq '{lineage, serial}'
tofu -chdir=<root> state list
```

이전 전후의 resource address, instance index, remote object ID가 모두 같아야 한다. 빈 backend에
기록할 때 OpenTofu가 새 lineage와 serial을 만들 수 있으므로 두 값은 증거로 기록한다. 열 개
root를 모두 이전한 뒤 `ghilbut-tfstates-v2`에 열 개 state object가 있어야 한다.

## 5. 실행 경로 검증

Management, Domains, Platform, UltaryDomains source profile로 각 backend를 읽고 lock을
생성할 수 있어야 한다. 모든 root에서 plan을 실행하고 state migration과 무관한 기존 drift는
별도로 기록한다.

## 6. 기존 bucket 삭제

모든 backend와 state consumer가 `ghilbut-tfstates-v2`를 사용한 뒤 기존 bucket policy를
삭제한다. 비활성 state의 resource address가 활성 Foundation accounts state에 모두 포함되는지
확인한다. 기존 bucket의 object version과 delete marker를 모두 삭제한 뒤 bucket을 삭제한다.

```sh
AWS_PROFILE=ghilbut-tofu-apply-for-workloads-domains \
  aws s3api delete-bucket-policy --bucket ghilbut-tfstates
```

## 7. 최종 bucket

Platform state bucket 이름은 `ghilbut-tfstates-v2`다. `ghilbut-tfstates` 생성 명령을 실행하지
않는다. 모든 backend, remote state, IAM policy는 v2만 참조한다.
