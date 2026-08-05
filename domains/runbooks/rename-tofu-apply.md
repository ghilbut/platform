---
status: running
issue: 119
---

# Rename the Domains OpenTofu execution role

## Result

Domains account `869061964712`는 `tofu-apply` 역할을 사용한다.
`TofuApplyForDomains`만 이 역할을 수임한다.

## Bootstrap

1. `TofuApplyForDomains`에 기존 역할과 새 역할의 assume 권한을 함께 부여한다.
2. 새 역할 하나에 필요한 IAM 생성·조회·수정·삭제 권한을 임시로 부여한다.
3. Direct SSO provider로 `tofu-apply` 역할과 `tofu-apply-inline` 정책을 생성한다.
4. 새 역할을 직접 수임하고 caller account `869061964712`를 확인한다.

## Switch

1. Domains provider를 `arn:aws:iam::869061964712:role/tofu-apply`로 변경한다.
2. 전체 Domains plan이 `No changes`인지 확인한다.
3. 기존 역할과 inline policy의 state 주소를 legacy 주소로 이동한다.
4. 새 역할을 사용하는 provider로 기존 역할과 inline policy를 삭제한다.
5. 새 역할과 inline policy의 state 주소를 표준 주소로 이동한다.

## Finalize

1. `TofuApplyForDomains`에서 기존 역할 assume 권한과 임시 IAM 권한을 제거한다.
2. IAM Identity Center provisioning이 `SUCCEEDED`인지 확인한다.
3. Identity와 Domains plan이 모두 `No changes`인지 확인한다.
4. Domains state address 수와 DNS resource address 집합이 변경되지 않았는지 확인한다.
5. `tofu-apply-domains` 역할이 없는지 확인한다.
