---
type: rulebook
area: aws
---

# AWS 개발자 접근 기준

이 문서는 IAM Identity Center `Developers` 그룹의 AWS 읽기 전용 접근 범위를 정의한다.

## 참조 소스

- 보안 원칙: [[knowledge/rulebooks/SECURITY|보안 기준]]
- 계정 할당과 프로필: [[aws/README#Developer access|AWS architecture]]
- IAM 정책 구현: [Developers Permission Set](../../../aws/foundation/identity/tofu/developers.tf)
- 설정과 검증 절차: [[aws/RUNBOOK#Developer access verification|AWS 운영 Runbook]]

## 접근 정책

`Developers`는 할당된 AWS 계정의 모든 관측 정보를 열람한다. AWS 리소스를 변경하거나 다른 역할을
수임하지 못한다.

| 개발자 열람 | 정보 |
|---|---|
| 허용 | 리소스 이름, ARN, 태그, 상태, 구성과 연결 관계 |
| 허용 | IAM 역할, 신뢰 정책과 권한 정책 |
| 허용 | 네트워크 경계, 공개 DNS 레코드, 인증서와 지표 |
| 허용 | `Developers`가 할당된 계정의 로그, 추적과 보안 탐지 결과 |
| 허용 | 비밀 리소스와 파라미터의 이름, ARN, 유형, 버전, 교체 상태, 정책과 태그 |
| 허용 | S3 `bucket` 구성과 객체의 `key`, `prefix`, 크기, 수정 시각, 버전, 저장 유형과 태그 |
| 거부 | 비밀값, 파라미터값, 애플리케이션 설정값과 자격 증명 |
| 거부 | S3 객체, OpenTofu state, 백업, database record, queue message와 stream record 본문 |
| 거부 | 개인정보, 도메인 등록자 연락처와 고객·직원 디렉터리 정보 |
| 거부 | 비용, 결제, 구매, 계약, 법적 보존 정보와 AWS Support case |
| 거부 | 비공개 코드와 container image 본문 |

## 데이터 배치 기준

[[knowledge/rulebooks/SECURITY#데이터 배치|데이터 배치 기준]]을 따른다. AWS 서비스가 필드나
작업 단위 접근 제어를 지원하지 않으면 계정을 분리한다.
