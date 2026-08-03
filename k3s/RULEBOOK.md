---
type: rulebook
area: k3s
---

# K3s RULEBOOK

## A. RUNBOOK

### 1. 문서 책임

- RUNBOOK.md는 K3s의 공통 설치 절차를 관리한다.
- runbooks/<CLUSTER>.md는 특정 클러스터의 실행 결과를 기록한다.

### 2. 실행 문서 Properties

runbooks/<CLUSTER>.md에는 다음 Properties를 기록한다.

| Property | 값 |
| --- | --- |
| type | run |
| area | k3s |
| cluster | 클러스터 이름 |
| status | planned, failed, completed 중 하나 |
| planned_at | PLAN 문서 생성일. `YYYY-MM-DD` |
| completed_at | 설치 완료일. `YYYY-MM-DD` |

### 3. 실행 절차

1. 실행 전에 `runbooks/<CLUSTER>.md`에 실행별 값과 전체 shell command를 작성한다.
2. 실행이 끝나면 수행 결과와 완료 날짜를 기록한다.
3. 실패하면 status를 `failed`로 설정하고 발생 위치와 관찰 결과를 기록한다.
