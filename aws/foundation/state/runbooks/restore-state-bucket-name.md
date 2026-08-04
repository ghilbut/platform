---
status: running
issue: 117
---

# Restore the OpenTofu state bucket name

## Result

Platform account `012646747332`은 `ghilbut-tfstates` bucket을 소유한다. 모든 active
OpenTofu backend는 이 bucket을 사용한다.

## Safety rules

- State object는 `tofu init -migrate-state`로만 이동한다.
- Source state의 address와 remote ID를 target state에서 확인한다.
- 열 개 root의 target plan이 변경 없음을 확인한 후 `ghilbut-tfstates-v2`를 삭제한다.
- State bucket version ID를 각 변경 전에 기록한다.
- State 값은 출력하지 않는다.

## Source recovery versions

| State key | Source version ID |
|---|---|
| `k3s.tfstate` | `PwJpASgK0NOQYRLaJUqkIwRsl8FhMj6Q` |
| `platform/apps.tfstate` | `Miqhuf0TGMc76n4j_yWrpSXs46ILxSpI` |
| `platform/aws/cdn.tfstate` | `1SB9TVs1Qxl9JD6TTIfa2h5NjQZSBHaO` |
| `platform/aws/foundation/accounts.tfstate` | `JOZujQ2i7aAbBtwKJkeHuZaD7yhvcj7c` |
| `platform/aws/foundation/identity.tfstate` | `oejiU8ySBImEAtjfETU7dZQm6azYO4Bq` |
| `platform/aws/foundation/state.tfstate` | `sVEoiMcq5YNKoG8ZfGZ0p3fZI3PhTvQC` |
| `platform/aws/foundation/workload.tfstate` | `FH_9VItfZSrfA.OE9HnyugI.S81Fvl6o` |
| `platform/domains.tfstate` | `0r6zBLvXxmNnmxLbtQXng7Sjr_fXpa3z` |
| `platform/github.tfstate` | `095xUp5z7inkUi3K_kIU77cPsfLOrfiw` |
| `ultary/domains.tfstate` | `FFocE5syXRYjKZIRUnDM5fbATGi2LvuM` |

## Bootstrap plans

`/tmp/issue-117-state-bootstrap.tfplan`은 다음 여섯 resource만 생성한다.

- `aws_s3_bucket.state["primary"]`
- `aws_s3_bucket_ownership_controls.state["primary"]`
- `aws_s3_bucket_public_access_block.state["primary"]`
- `aws_s3_bucket_server_side_encryption_configuration.state["primary"]`
- `aws_s3_bucket_versioning.state["primary"]`
- `aws_s3_bucket_policy.state["primary"]`

기존 여섯 resource는 `legacy` 주소로 이동하며 remote change가 없다. Bootstrap plan은
`6 add, 0 change, 0 destroy`다.

`/tmp/issue-117-identity-bootstrap.tfplan`은 네 `TofuApplyFor*` inline policy에 두 state
bucket을 함께 허용한다. Plan은 `0 add, 4 change, 0 destroy`다.

## Bootstrap apply

```sh
AWS_PROFILE=ghilbut-tofu-apply-for-workloads AWS_SDK_LOAD_CONFIG=1 \
  tofu -chdir=aws/foundation/state/tofu apply \
  /tmp/issue-117-state-bootstrap.tfplan

AWS_PROFILE=ghilbut-tofu-apply-for-management AWS_SDK_LOAD_CONFIG=1 \
  tofu -chdir=aws/foundation/identity/tofu apply \
  /tmp/issue-117-identity-bootstrap.tfplan
```

Bucket의 versioning, AES256 encryption, BucketOwnerEnforced ownership, public access block과
bucket policy를 직접 확인한다. IAM Identity Center provisioning status는 모두
`SUCCEEDED`여야 한다.

## Backend migration order

| Order | Root | Source profile |
|---:|---|---|
| 1 | `aws/foundation/accounts/tofu` | `ghilbut-tofu-apply-for-management` |
| 2 | `aws/foundation/identity/tofu` | `ghilbut-tofu-apply-for-management` |
| 3 | `aws/foundation/state/tofu` | `ghilbut-tofu-apply-for-workloads` |
| 4 | `aws/foundation/workload/tofu` | `ghilbut-tofu-apply-for-workloads` |
| 5 | `github/tofu` | `ghilbut-tofu-apply-for-workloads` |
| 6 | `aws/cdn/tofu` | `ghilbut-tofu-apply-for-workloads` |
| 7 | `apps/tofu` | `ghilbut-tofu-apply-for-workloads` |
| 8 | `k3s/tofu` | `ghilbut-tofu-apply-for-workloads` |
| 9 | `domains/tofu` | `ghilbut-tofu-apply-for-domains` |
| 10 | `ultary/domains/tofu` | `ghilbut-tofu-apply-for-ultary-domains` |

각 root에서 backend bucket을 `ghilbut-tfstates`로 변경한 후 다음 명령을 실행한다.

```sh
AWS_PROFILE=<source-profile> AWS_SDK_LOAD_CONFIG=1 \
  tofu -chdir=<root> init -migrate-state
```

## Verification

- Target bucket에는 열 개 current state object와 lock object 0개가 있다.
- 각 root의 state address 집합과 remote ID는 source와 같다.
- 각 root의 refreshed plan은 변경이 없다.
- Identity Center inline policy와 CDN GitHub Actions role은 target bucket만 허용한다.
- Repository에는 `ghilbut-tfstates-v2` 참조가 없다.

## Legacy bucket removal

Target 검증 후 `ghilbut-tfstates-v2`의 모든 object version과 delete marker를 삭제한다.
빈 bucket을 삭제하고 state root에서 여섯 `legacy` 주소를 제거한다. 최종 state root plan은
변경이 없어야 한다.
