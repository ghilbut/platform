---
title: AWS 관리 계정 제어
---

# AWS 관리 계정 제어

`tofu/`는 IAM Identity Center의 `tofu` 권한 세트에 권한 경계를 연결한다. 이 권한 세트는
모든 AWS 계정에서 같은 이름의 고객 관리형 정책을 권한 경계로 사용하므로, 정책을 세 계정에
함께 생성한다.

관리 계정에서는 AWS Organizations, AWS 계정 관리, IAM Identity Center, 청구와 비용 관리,
AWS Support, Trusted Advisor만 허용한다. 그 밖의 API 호출은 명시적으로 거부한다.

AWS는 기본 활성 리전(예: `us-east-1`)을 비활성화할 수 없다. 그러나 권한 경계가
`us-east-1`을 포함한 모든 리전에서 워크로드 API를 거부하고 `account:EnableRegion`을
거부한다. opt-in 리전 비활성화는 `aws/accounts/tofu/modules/management/`가 관리한다.

AWS 계정 루트 사용자와 서비스 연결 역할에는 이 권한 경계가 적용되지 않는다. 루트 사용자에는
MFA를 설정하고, 관리 계정에 별도의 IAM 사용자나 이 권한 경계 밖의 역할을 만들지 않는다.

OpenTofu 작업 절차는 [OpenTofu 규칙](../../docs/TOFU.md)을 따른다.
