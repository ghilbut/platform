---
type: rulebook
area: k3s
---

# K3s RULEBOOK

## A. RUNBOOK

### 1. 문서 책임

- RUNBOOK.md는 K3s의 공통 설치 절차를 관리한다.
- RUN-<CLUSTER>-YYYY-mm-dd.md는 특정 클러스터의 실행 결과를 기록한다.

### 2. 실행 문서 Properties

RUN-<CLUSTER>-YYYY-mm-dd-PLAN.md, RUN-<CLUSTER>-YYYY-mm-dd.md, RUN-<CLUSTER>-YYYY-mm-dd-FAILED.md에는 다음 Properties를 기록한다.

| Property | 값 |
| --- | --- |
| type | run |
| area | k3s |
| cluster | 클러스터 이름 |
| status | planned, failed, completed 중 하나 |
| planned_at | PLAN 문서 생성일. `YYYY-MM-DD` |
| completed_at | 설치 완료일. `YYYY-MM-DD` |

### 3. 실행 절차

1. 실행 전에 RUN-<CLUSTER>-YYYY-mm-dd-PLAN.md를 작성한다.
2. PLAN 문서에는 실행별 값과 전체 쉘 커맨드를 작성한다. 쉘 커맨드를 순서대로 복사해 실행하면 절차가 완료되어야 한다.
3. 절차가 성공하면 결과를 기록하고 RUN-<CLUSTER>-YYYY-mm-dd.md로 이름을 변경한다.
4. 문서 절차를 그대로 실행했는데 문제가 발생하면 RUN-<CLUSTER>-YYYY-mm-dd-FAILED.md로 이름을 변경하고, 문제가 발생한 위치와 관찰한 결과를 기록한다.
5. 실패 원인을 해결해 절차를 완료하면 완료 시점의 날짜로 RUN-<CLUSTER>-YYYY-mm-dd.md로 이름을 변경하고 결과를 기록한다.
