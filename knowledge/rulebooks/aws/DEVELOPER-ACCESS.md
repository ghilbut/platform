---
type: rulebook
area: aws
---

# AWS 개발자 접근 기준

이 문서는 IAM Identity Center `Developers` 그룹의 AWS 읽기 전용 접근 범위를 정의한다.

## 참조 소스

- 계정 할당과 프로필: [[aws/README#Developer access|AWS architecture]]
- IAM 정책 구현: [Developers Permission Set](../../../aws/foundation/identity/tofu/developers.tf)
- 설정과 검증 절차: [[aws/RUNBOOK#Developer access verification|AWS 운영 Runbook]]

## 접근 정책

`Developers`는 AWS 리소스를 변경하거나 다른 역할을 수임하지 못한다. 리소스 이름과 구성은 보안
경계로 사용하지 않는다. IAM, 네트워크, 암호화와 리소스 정책이 변경과 데이터 접근을 차단한다.

| 개발자 열람 | 정보 |
|---|---|
| 허용 | 리소스 이름, ARN, 태그, 상태, 구성과 연결 관계 |
| 허용 | IAM 역할, 신뢰 정책과 권한 정책 |
| 허용 | 네트워크 경계, 공개 DNS 레코드, 인증서와 지표 |
| 허용 | `Developers`가 할당된 계정의 로그, 추적과 보안 탐지 결과 |
| 허용 | 비밀 리소스와 파라미터의 이름, ARN, 유형, 버전, 교체 상태, 정책과 태그 |
| 제한 | 비밀값, 파라미터값, 애플리케이션 설정값과 자격 증명 |
| 제한 | S3 객체 본문, 데이터베이스 레코드, 대기열 메시지와 스트림 레코드 |
| 제한 | OpenTofu state, 백업 객체, 비공개 코드와 컨테이너 이미지 |
| 제한 | 개인정보, 도메인 등록자 연락처와 고객·직원 디렉터리 정보 |
| 제한 | 비용, 결제, 구매, 계약, 법적 보존 정보와 AWS Support case |
| 제한 | AWS Organizations, IAM Identity Center, 조직 단위 관측성 설정과 CloudTrail 이벤트 이력 |

## 데이터 배치 기준

- 표에서 열람을 제한한 정보를 개발자 열람이 허용된 이름, 설명, 태그, 구성, 로그, 추적과 보안 탐지
  결과에 저장하지 않는다.
- 표에서 열람을 제한한 정보가 포함된 로그, 추적과 보안 탐지 결과는 `Developers`가 할당되지 않은
  계정에 저장한다.
- AWS 서비스가 필드 단위 접근 제어를 지원하지 않으면 계정을 분리한다.
