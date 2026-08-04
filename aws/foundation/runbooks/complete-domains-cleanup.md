---
status: running
issue: 99
---

# Complete Domains cleanup

## Final responsibility

Domains account `869061964712`은 다음 resource만 유지한다.

- `ghilbut.com`, `ghilbut.net` domain registration과 hosted zone
- `TofuApplyForDomains`, `tofu-apply-domains`
- CPA IAM OIDC provider와 DNS 전용 role 2개
- `PendingDeletion` KMS key `6ebc75ad-c084-4c1a-842e-b45482e5e668`
- AWS-managed account baseline

Live budget 수는 0이다.

## Live cleanup result

직접 service API에서 다음 resource는 없다.

| Resource | Identifier |
|---|---|
| IAM role | `tofu-apply`, `cashflow-SMS-Role` |
| IAM policy | `service-role/Cognito-1480509629079` |
| Virtual MFA | `Authapp` |
| ECS task definition | `finpc-*` |
| CloudWatch alarm | `Budgets_Actual_1467215008539` |
| SNS topic | `aws_budget_da141ba7-4c82-4095-8f6e-e7a9d0d8c63f` |
| Resource Explorer | view 1개와 local index 3개 |

Resource Explorer의 마지막 search 결과와 IAM, KMS, S3, Budgets, CloudWatch, SNS, ECS, Cognito
direct API 결과를 비교했다. Direct API 결과를 지연된 index record보다 우선한다.

## State recovery

| State object | Version ID |
|---|---|
| Budget inspection apply 이전 identity state | `nKeoDcMGA3VAyHZc.YJDpRBsendiU8y4` |
| Final identity apply 이전 identity state | `RqzyBb3Jfl5HgwK0xbOuznUziG9d.lh8` |
| Final bucket-policy apply 이전 state state | `6siei0B87pPDudGX.vlrt7Kb.06u2isl` |

## Final saved plans

### Identity

`/tmp/issue-99-identity-final.tfplan`은 `0 add, 3 change, 1 destroy`다.

- `TofuApplyForDomains`에서 budget inspection 권한을 제거한다.
- `TofuApplyForWorkloads` assume-role ARN을 Platform `tofu-apply` 하나로 제한한다.
- Domains의 `TofuApplyForWorkloads` assignment 하나를 삭제한다.
- Platform assignment와 `TofuApplyForDomains` assignment는 변경하지 않는다.

### State

`/tmp/issue-99-state-final.tfplan`은 `0 add, 1 change, 0 destroy`다. Bucket policy에서 Domains
`TofuApplyForWorkloads` state access만 제거한다.

### Apps

`/tmp/issue-99-apps-platform.tfplan`은 변경이 없다. Backend와 provider는 Platform profile과
account `012646747332`를 사용한다.

## Apply

```sh
AWS_PROFILE=ghilbut-tofu-apply-for-workloads \
  tofu -chdir=aws/foundation/state/tofu apply \
  /tmp/issue-99-state-final.tfplan

AWS_PROFILE=ghilbut-tofu-apply-for-management \
  tofu -chdir=aws/foundation/identity/tofu apply \
  /tmp/issue-99-identity-final.tfplan
```

State access를 먼저 제거하고 account assignment를 마지막에 제거한다.

## Verify

```sh
aws sts get-caller-identity --profile ghilbut-tofu-apply-for-domains
aws sts get-caller-identity --profile ghilbut-tofu-apply-for-workloads

AWS_PROFILE=ghilbut-tofu-apply-for-management \
  tofu -chdir=aws/foundation/identity/tofu plan
AWS_PROFILE=ghilbut-tofu-apply-for-workloads \
  tofu -chdir=aws/foundation/state/tofu plan
AWS_PROFILE=ghilbut-tofu-apply-for-workloads \
  tofu -chdir=apps/tofu plan
```

각 plan은 변경이 없다. IAM Identity Center의 Domains assignment는 `TofuApplyForDomains`
하나다. Platform assignment는 `TofuApplyForWorkloads` 하나다.
