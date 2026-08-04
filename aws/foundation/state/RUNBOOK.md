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

## 대상

| Root | State key | Migration profile |
|---|---|---|
| `aws/foundation/accounts/tofu/` | `platform/aws/foundation/accounts.tfstate` | `ghilbut-tofu-apply-for-management` |
| `aws/foundation/identity/tofu/` | `platform/aws/foundation/identity.tfstate` | `ghilbut-tofu-apply-for-management` |
| `aws/foundation/state/tofu/` | `platform/aws/foundation/state.tfstate` | `ghilbut-tofu-apply-for-workloads` |
| `aws/foundation/workload/tofu/` | `platform/aws/foundation/workload.tfstate` | `ghilbut-tofu-apply-for-workloads` |
| `aws/cdn/tofu/` | `platform/aws/cdn.tfstate` | `ghilbut-tofu-apply-for-workloads-domains` |
| `domains/tofu/` | `platform/domains.tfstate` | `ghilbut-tofu-apply-for-workloads-domains` |
| `apps/tofu/` | `platform/apps.tfstate` | `ghilbut-tofu-apply-for-workloads-domains` |
| `github/tofu/` | `platform/github.tfstate` | `ghilbut-tofu-apply-for-workloads-domains` |
| `k3s/tofu/` | `k3s.tfstate` | `ghilbut-tofu-apply-for-workloads-domains` |
| `ultary/domains/tofu/` | `ultary/domains.tfstate` | `ghilbut-tofu-apply-for-workloads-domains` |

`platform/aws/accounts.tfstate`는 비활성 state다. 활성 Foundation accounts state와 resource
address를 대조한 뒤 기존 bucket과 함께 삭제한다.

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
```

## 2. 기존 bucket policy state 분리

기존 bucket policy는 모든 backend 이전이 끝날 때까지 AWS에 유지한다. state에서만 분리한다.

```sh
export AWS_PROFILE=ghilbut-tofu-apply-for-workloads-domains

tofu -chdir=aws/foundation/state/tofu state pull > /tmp/issue-97-state-before-detach.json
tofu -chdir=aws/foundation/state/tofu state rm aws_s3_bucket_policy.foundation_state_access
aws s3api get-bucket-policy --bucket ghilbut-tfstates
```

## 3. Platform bucket 생성

state root provider는 Platform `tofu-apply` 역할을 사용한다. 새 bucket이 생기기 전에는 backend
block의 bucket 값만 명령행에서 기존 bucket으로 덮어쓴다.

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
tofu -chdir=<root> state pull | jq '{lineage, serial}'
tofu -chdir=<root> init -migrate-state -force-copy
tofu -chdir=<root> state pull | jq '{lineage, serial}'
tofu -chdir=<root> state list
```

이전 전후 lineage는 같아야 한다. state 변경이 없는 root의 serial도 같아야 한다. 열 개 root를
모두 이전한 뒤 `ghilbut-tfstates-v2`에 열 개 state object가 있어야 한다.

## 5. 실행 경로 검증

Management, Domains, Platform, UltaryDomains source profile로 각 backend를 읽고 lock을
생성할 수 있어야 한다. 모든 root에서 plan을 실행하고 state migration과 무관한 기존 drift는
별도로 기록한다.

## 6. 기존 bucket 삭제

모든 backend와 state consumer가 `ghilbut-tfstates-v2`를 사용한 뒤 기존 bucket policy를
삭제한다. 비활성 state의 resource address가 활성 Foundation accounts state에 모두 포함되는지
확인한다. 기존 bucket의 object version과 delete marker를 모두 삭제한 뒤 bucket을 삭제한다.

## 7. 기존 이름 생성 시도

기존 bucket 삭제 후 Platform profile로 다음 명령을 정확히 한 번 실행한다.

```sh
AWS_PROFILE=ghilbut-tofu-apply-for-workloads \
  aws s3api create-bucket --bucket ghilbut-tfstates --region us-east-1
```

성공하면 새 bucket을 state root에 import하고 모든 backend를 같은 방식으로
`ghilbut-tfstates-v2`에서 `ghilbut-tfstates`로 이전한다. 모든 root 검증 후 v2를 삭제한다.
`BucketAlreadyExists`이면 v2를 유지하고 코드와 문서의 bucket 이름을 v2로 확정한다.
