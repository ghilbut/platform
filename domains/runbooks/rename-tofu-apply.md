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
2. 기존 역할과 새 역할에 필요한 IAM 생성·조회·수정·삭제 권한을 임시로 부여한다.
3. 기존 역할 resource의 provider를 direct SSO bootstrap provider로 변경한다.
4. Direct SSO bootstrap provider로 `tofu-apply` 역할과 `tofu-apply-inline` 정책을 생성한다.
5. Bootstrap provider는 `ghilbut-tofu-apply-for-domains` profile과 Domains account
   `869061964712`를 고정한다.
6. 새 역할을 직접 수임하고 caller account `869061964712`를 확인한다.

## Switch

1. Default Domains provider를 `arn:aws:iam::869061964712:role/tofu-apply`로 변경한다.
   기존 역할과 새 역할 resource는 bootstrap provider를 유지한다.
2. 기존 역할과 새 역할 block을 함께 선언한 상태에서 전체 Domains plan이
   `No changes`인지 확인한다.
3. 기존 역할과 inline policy block을 제거한다. Bootstrap provider를 유지한 plan은
   기존 IAM resource 두 개만 삭제한다.
4. 기존 역할 삭제 plan `0 add, 0 change, 2 destroy`를 적용한다.
5. 새 역할과 inline policy state 주소를 표준 주소로 이동한다.
6. 새 역할 block 이름과 output을 표준 주소로 변경하고 bootstrap provider를 제거한다.
7. 전체 Domains plan이 `No changes`인지 확인한다.

## Finalize

1. `TofuApplyForDomains`에서 기존 역할 assume 권한과 임시 IAM 권한을 제거한다.
2. IAM Identity Center provisioning이 `SUCCEEDED`인지 확인한다.
3. Identity와 Domains plan이 모두 `No changes`인지 확인한다.
4. Domains state address 수와 DNS resource address 집합이 변경되지 않았는지 확인한다.
5. `tofu-apply-domains` 역할이 없는지 확인한다.
