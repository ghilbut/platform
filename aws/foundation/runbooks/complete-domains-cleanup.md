---
status: running
issue: 99
---

# Complete Domains cleanup

## 완료 조건

- Domains에는 domain registration, Route 53, account budget, DNS용 IAM federation과 AWS-managed
  account baseline만 남는다.
- `TofuApplyForDomains`는 Domains에 유지한다.
- `TofuApplyForWorkloads`는 Platform에만 할당한다.
- Apps state와 provider는 Platform의 `ghilbut-tofu-apply-for-workloads` profile을 사용한다.
- `ghilbut-tofu-apply-for-workloads-domains`와 `ghilbut-platform` local profile은 삭제한다.

Vault resource는 없다. KMS key `6ebc75ad-c084-4c1a-842e-b45482e5e668`은
`2026-09-04T01:16:50.578000+09:00`에 삭제된다.

## 1. 현재 리소스 확인

직접 service API 결과를 AWS Resource Explorer 결과보다 우선한다.

| Resource | 현재 상태 | 처리 |
|---|---|---|
| IAM `tofu-apply` | 존재 | 모든 cleanup 이후 삭제 |
| IAM `cashflow-SMS-Role` | 존재, last-used 없음 | 연결 policy와 함께 삭제 |
| IAM policy `service-role/Cognito-1480509629079` | role 1개에 연결 | 삭제 |
| Virtual MFA `Authapp` | 직접 IAM API에서 없음 | 완료 |
| ECS `finpc-*` task definition | 직접 ECS API에서 없음 | 완료 |
| CloudWatch `Budgets_Actual_1467215008539` | 존재 | budget 연결 확인 후 삭제 |
| SNS `aws_budget_da141ba7-4c82-4095-8f6e-e7a9d0d8c63f` | subscriber 없음 | budget 연결 제거 후 삭제 |
| Resource Explorer | view 1개, local index 3개 | 최종 inventory 후 삭제 |

Domains의 live IAM Identity Center assignment는 `TofuApplyForDomains`와
`TofuApplyForWorkloads`다.

## 2. Budget 확인 권한과 Apps 경로 적용

이 단계는 Domains의 resource를 삭제하지 않는다.

```sh
export AWS_PROFILE=ghilbut-tofu-apply-for-management
tofu -chdir=aws/foundation/identity/tofu init -reconfigure
tofu -chdir=aws/foundation/identity/tofu plan \
  -out=/tmp/issue-99-budget-access.tfplan
tofu -chdir=aws/foundation/identity/tofu show \
  /tmp/issue-99-budget-access.tfplan
tofu -chdir=aws/foundation/identity/tofu apply \
  /tmp/issue-99-budget-access.tfplan

export AWS_PROFILE=ghilbut-tofu-apply-for-workloads
tofu -chdir=apps/tofu init -reconfigure
tofu -chdir=apps/tofu plan -out=/tmp/issue-99-apps-platform.tfplan
tofu -chdir=apps/tofu show /tmp/issue-99-apps-platform.tfplan
```

`TofuApplyForDomains`는 account budget의 조회와 notification 변경 권한만 가진다.
`billing:GetBillingViewData`는 budget 조회에 필요한 billing view 읽기 권한이다.

## 3. Budget notification 정리

```sh
export AWS_PROFILE=ghilbut-tofu-apply-for-domains
aws budgets describe-budgets \
  --account-id 869061964712
```

Budget과 notification, subscriber를 확인한 뒤 사용하지 않는 notification을 budget에서 삭제한다.
CloudWatch alarm이 사라진 것을 확인하고 subscriber가 없는 SNS topic을 삭제한다. Budget은 account
billing baseline으로 유지한다.

## 4. 사용자 관리 리소스 삭제

삭제 전 AWS Resource Explorer search 결과와 각 service의 직접 API 결과를 비교한다.

1. `cashflow-SMS-Role`에서 `Cognito-1480509629079` policy를 분리한다.
2. role, policy, budget notification resource를 삭제한다.
3. Resource Explorer view와 local index 3개를 삭제한다.
4. Domains `tofu-apply` session을 새로 발급한다.
5. `tofu-apply-inline`, `IAMFullAccess`, `PowerUserAccess`를 제거하고 role을 삭제한다.

## 5. Workload access 제거

변경 전 다음 state object version ID를 기록한다.

- `platform/aws/foundation/identity.tfstate`
- `platform/aws/foundation/state.tfstate`

최종 구성은 다음 항목을 제거한다.

- `TofuApplyForWorkloads`의 Domains account assignment
- `TofuApplyForWorkloads`의 Domains `tofu-apply` assume-role ARN
- Foundation state bucket policy의 `domains_workloads` access
- temporary Domains workload profile을 사용하는 문서

Identity plan은 Platform assignment를 변경하지 않는다. State plan은 Platform, Management,
Domains, UltaryDomains access를 변경하지 않는다.

## 6. 완료 확인

```sh
aws sts get-caller-identity --profile ghilbut-tofu-apply-for-domains
aws sts get-caller-identity --profile ghilbut-tofu-apply-for-workloads

AWS_PROFILE=ghilbut-tofu-apply-for-management \
  tofu -chdir=aws/foundation/identity/tofu plan
AWS_PROFILE=ghilbut-tofu-apply-for-workloads \
  tofu -chdir=aws/foundation/state/tofu plan
AWS_PROFILE=ghilbut-tofu-apply-for-workloads \
  tofu -chdir=apps/tofu plan
AWS_PROFILE=ghilbut-tofu-apply-for-domains \
  tofu -chdir=domains/tofu plan
```

네 plan은 변경이 없다. Domains의 직접 service API inventory에는 DNS, account budget,
DNS federation, PendingDeletion KMS key와 AWS-managed baseline만 남는다.
