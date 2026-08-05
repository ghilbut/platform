---
status: cleanup-pending
issue: 117
---

# Restore the OpenTofu state bucket name

## Result

Platform account `012646747332`은 `ghilbut-tfstates` bucket을 소유한다. 모든 active
OpenTofu backend는 이 bucket을 사용한다.

## Safety rules

- Resource를 포함한 state object는 `tofu init -migrate-state`로 이동한다.
- Resource와 output이 없는 Apps state는 기록된 source version을 S3 CopyObject로 복사한다.
- Source state의 address와 remote ID를 target state에서 확인한다.
- 아홉 root의 target plan이 변경 없음을 확인한다.
- K3s는 source와 target의 address, remote ID, output 해시를 확인하고 source version을
  target의 전용 recovery key에 보관한다.
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

`2026-08-05T08:16:53+09:00`에 bucket을 생성했다. Bucket resource 여섯 개를
적용했다. Versioning은
`Enabled`, encryption은 `AES256`, ownership은 `BucketOwnerEnforced`다. Public access
block의 네 설정은 모두 `true`다.

네 permission set provisioning은 `2026-08-05T08:17:13+09:00`부터
`2026-08-05T08:17:15+09:00`까지 완료됐고 모두 `SUCCEEDED`다.

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
  tofu -chdir=<root> init -migrate-state -force-copy -input=false
```

`platform/apps.tfstate`는 resource와 output이 0개인 state다. OpenTofu는 이 빈 state를
target에 기록하지 않는다. Source version `Miqhuf0TGMc76n4j_yWrpSXs46ILxSpI`를
S3 CopyObject로 복사한다. Target은 source와 같은 lineage
`26c2da05-7f71-2187-5e04-33d5be7dc4c5`, serial `2`를 가진다.

## Verification

`2026-08-05T09:30:37+09:00`의 target 확인 결과다.

| Root | Address count | Target version ID | Plan |
|---|---:|---|---|
| `aws/foundation/accounts/tofu` | 21 | `CfMElmLRYobdDW_aZnNKVcT4CeluGYmc` | No changes |
| `aws/foundation/identity/tofu` | 34 | `QGZW4Sbpp0kcOC.K7GaWQsrQlvdaTGZn` | No changes |
| `aws/foundation/state/tofu` | 14 | `blIixq4rqEwfWHdmghZ4odXSbpQYNzN6` | No changes |
| `aws/foundation/workload/tofu` | 6 | `CQmM9vXWTbpoBAn6zTk14Kzt1WxVKLcs` | No changes |
| `github/tofu` | 1 | `ll.X9ByDXGFEncmGNcnFOF5WBzog0c8m` | No changes |
| `aws/cdn/tofu` | 23 | `SCFJYCLGoeAB82R.HpuJ7F5Xc5CbX188` | No changes |
| `apps/tofu` | 0 | `3PtxtW1Pd5VGaq8wWriNb6fWScK6js9V` | No changes |
| `k3s/tofu` | 2 | `9SUHJmE3vgvgX0wDFph7GjTriiNhEpng` | Kubernetes API 연결 거부 |
| `domains/tofu` | 28 | `UCw0Wl2GlRyD9hYTowovvQ8CPv5IupXF` | No changes |
| `ultary/domains/tofu` | 50 | `qeACK2WwRUQUyo2cT5ln3tf9zPaG.ml0` | No changes |

- Target에는 active state object 10개, K3s recovery object 1개, current lock object 0개가
  있다.
- 각 target의 address와 remote ID 해시는 source version과 같다.
- 각 target의 output 해시는 source version과 같다.
- K3s plan은 `192.168.254.4:6443` 연결 거부로 중단된다. State address 2개와 remote ID는
  source와 같다. Source version `PwJpASgK0NOQYRLaJUqkIwRsl8FhMj6Q`는
  `recovery/issue-117/k3s.tfstate`에 보관한다. Recovery version ID는
  `XzksMEqD4b6MdAc7QmlPH_SG5CiEw7S9`이고 canonical JSON SHA-256은
  `2a4afad143a44df432b9473953cfe85466b3e5510e1d5e2246433a06ff26ad4e`다.
- CDN GitHub Actions role은 target bucket만 허용한다.

## Cleanup readiness

`2026-08-05T09:42:40+09:00`에 State address는 7개이고 State plan은
`No changes`다. Identity narrowing apply는 `0 add, 4 change, 0 destroy`다. 다음
provisioning request는 모두 `SUCCEEDED`다.

| Created at | Request ID |
|---|---|
| `2026-08-05T09:42:09.274000+09:00` | `dae35353-fab9-41ba-9b0e-20dc869b3e19` |
| `2026-08-05T09:42:09.280000+09:00` | `59476d73-adf4-4613-b985-49bea40b8aca` |
| `2026-08-05T09:42:09.289000+09:00` | `e8785958-9735-43e2-9a0e-76ee94862c0a` |
| `2026-08-05T09:42:10.706000+09:00` | `2f9d68f7-42ea-4e6a-bedf-604463b18d1d` |

Identity plan은 `No changes`다. `*.tf` 파일의 `ghilbut-tfstates-v2` 참조는 0개다.

## Legacy bucket removal

`2026-08-05T09:30:37+09:00`에 source는 object version 223개와 delete marker 167개를
가진다.

삭제 작업은 `arn:aws:sts::012646747332:assumed-role/tofu-apply/issue-117-cleanup`을
사용한다.

1. State에서 다음 address 일곱 개를 `tofu state rm`으로 제거한다.
   - `data.aws_iam_policy_document.state["legacy"]`
   - `aws_s3_bucket.state["legacy"]`
   - `aws_s3_bucket_ownership_controls.state["legacy"]`
   - `aws_s3_bucket_policy.state["legacy"]`
   - `aws_s3_bucket_public_access_block.state["legacy"]`
   - `aws_s3_bucket_server_side_encryption_configuration.state["legacy"]`
   - `aws_s3_bucket_versioning.state["legacy"]`
2. State configuration에서 `legacy` instance와 `moved.tf`를 함께 제거한다.
3. State address가 7개이고 plan이 `No changes`인지 확인한다.
4. Identity Center inline policy 네 개를 target bucket만 허용하도록 변경한다.
5. Identity plan이 `0 add, 4 change, 0 destroy`인지 확인하고 적용한다.
6. Identity Center provisioning 네 건이 `SUCCEEDED`인지 확인한다.
7. Identity plan이 `No changes`인지 확인한다.
8. Source bucket 생성 시각이 `2026-08-04T22:12:46+09:00`인지 확인한다.
9. Source의 `platform/aws/foundation/state.tfstate` current version ID가
   `3tg_MR3UUiURoarImAD1aCipwY3iBWsL`인지 확인한다. Target의 current version ID
   `.N4pcdqvrKn1GzcSlvqsJCOx.UjcTWaC`와 달라야 한다.
10. `list-object-versions`의 `IsTruncated`가 `false`가 될 때까지 source를 조회한다.
11. 조회한 모든 version과 delete marker를 `Key`와 `VersionId`로 삭제한다. 한
    `delete-objects` 요청은 최대 1,000개를 포함한다. 223개 version과 167개 delete marker는
    삭제 전 참고 수치다.
12. Source의 version, delete marker, current object가 모두 0개인지 확인한다.
13. 빈 `ghilbut-tfstates-v2` bucket을 삭제한다.
14. Target의 active state object 10개, K3s recovery object 1개, current lock object 0개를
    확인한다.
15. `*.tf` 파일에서 `ghilbut-tfstates-v2` 참조가 0개인지 확인한다.
