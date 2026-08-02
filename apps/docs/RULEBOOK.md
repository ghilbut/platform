---
type: rulebook
area: apps
---

# Applications Documents RULEBOOK

`apps/docs/`의 하위 디렉터리는 한 애플리케이션의 문서를 관리한다.

## 문서 구성

- 각 애플리케이션 디렉터리에는 `README.md`를 반드시 둔다.
- `README.md`에는 애플리케이션의 목적과 관련 manifest, 인프라, 문서 디렉터리의 상대 링크를 기록한다.
- `RULEBOOK.md`, `RUN-PLAN.md`, `RUNBOOK.md`, `PLAYBOOK.md`는 필요한 경우에만 만든다.
- `RULEBOOK.md`는 애플리케이션 문서 또는 운영 규칙을, `RUN-PLAN.md`는 한 번 실행할 변경·설치 계획을, `RUNBOOK.md`는 반복 가능한 운영 절차를, `PLAYBOOK.md`는 장애 복구·이전 같은 예외 절차를 기록한다.
- `README.md`의 연결은 디렉터리 단위로 기록한다. Argo CD Application 정의는 예외로 해당 YAML 파일을 연결한다. 같은 문서 디렉터리의 문서를 나열하지 않는다.
- 파일명과 링크만으로 알 수 있는 설명을 반복하지 않는다.

## 링크와 Properties

- Markdown 문서는 [Obsidian 문서 규칙](../../docs/OBSIDIAN.md)을 따른다.
- 앱 문서는 이 RULEBOOK과 앱 `README.md`를 상대 링크로 연결한다.
- 관련 Argo CD Application manifest, OpenTofu root, K3s 구성 디렉터리는 앱 `README.md`에서 상대 링크로 추적한다.
