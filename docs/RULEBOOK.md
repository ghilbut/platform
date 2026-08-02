---
type: rulebook
area: documentation
---

# Documentation RULEBOOK

## RUNBOOK

### 문서 책임

- `RUNBOOK.md`는 반복 가능한 공통 운영 절차를 관리한다.
- `RUN-<SCOPE>-YYYY-mm-dd-PLAN.md`는 한 번 실행할 설치·변경 계획을 관리한다.
- `RUN-<SCOPE>-YYYY-mm-dd.md`는 성공한 실행 결과를 기록한다.
- `RUN-<SCOPE>-YYYY-mm-dd-FAILED.md`는 실패한 실행의 위치와 관찰 결과를 기록한다.

`<SCOPE>`에는 cluster 또는 application처럼 실행 대상을 식별하는 값을 사용한다.

### 실행 문서 Properties

실행 문서는 [RUN-PLAN](obsidian/templates/RUN-PLAN.md) 템플릿으로 시작하고 다음 Properties를 기록한다.

| Property | 값 |
| --- | --- |
| type | `run` |
| area | 문서 영역 |
| status | `planned`, `paused`, `failed`, `completed` 중 하나 |
| planned_at | PLAN 문서 생성일. `YYYY-MM-DD` |
| paused_at | 일시중단한 날짜. `status: paused`일 때 기록한다. `YYYY-MM-DD` |
| paused_step | 중단한 실행 절차의 번호와 작업. 예: `4단계: Argo CD 동기화 대기` |
| paused_reason | 재개 전에 해결하거나 확인할 사항. 비밀값을 기록하지 않는다. |
| completed_at | 실행 완료일. `YYYY-MM-DD` |

실행 대상이 명확해야 하는 경우 `cluster`, `application` 같은 Properties를 추가한다.

### 실행 절차

1. 실행 전에 PLAN 문서를 만든다.
2. PLAN 문서에는 실행별 값, 수동 확인 사항, 전체 shell command를 기록한다. 비밀값은 기록하지 않는다.
3. 문서의 shell command를 순서대로 실행해 절차를 완료할 수 있어야 한다.
4. 실행을 일시중단하면 파일명은 `-PLAN`으로 유지하고 `status: paused`, `paused_at`, `paused_step`, `paused_reason`을 기록한다. `결과`에는 완료한 단계와 관찰 결과를 기록한다.
5. 중단 사유를 해결해 재개하면 `status`를 `planned`로 바꾸고 `paused_at`, `paused_step`, `paused_reason`은 비운다. 이전 중단 기록은 `결과`에 남긴다.
6. 성공하면 결과를 기록하고 `-PLAN`을 제거한 파일명으로 바꾼다.
7. 절차를 그대로 실행했는데 실패하면 `-FAILED` 파일명으로 바꾸고 실패 위치와 관찰 결과를 기록한다.
8. 실패를 해결해 완료하면 완료 날짜의 결과 문서를 새로 기록한다.
