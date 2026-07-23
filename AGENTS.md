# Rules for Agents

* **게이트와 같은 모호한 표현을 금지한다.**
* 간결하고 명확하며 이해하기 쉬운 표현을 사용한다.
* 작업 범위에서 모순, 충돌, 모호함이 없는 상태를 유지한다.

## GitHub

* Branch 작업은 `.worktrees/` 디렉터리에서 한다.
* GitHub 작업은 Dokevy MCP가 반환한 워크플로, 공통 규칙과 정책을 따른다.
* 작업과 지원 역할의 매핑 정본은 Dokevy MCP 서버다. 도구별 지원 역할은 미지원 역할 호출에 서버가 반환하는 오류의 지원 역할 목록으로 확인한다.
* Dokevy는 모델 호출, Git 작업, GitHub 변경, 워크트리와 세션을 관리하지 않는다. Orchestrator가 이 작업을 수행한다.

GitHub 작업을 시작할 때 대상 번호를 해당 도구에 전달한다. 사용자가 피드백을 제공했으면 함께 전달한다. Orchestrator는 도구가 반환한 전체 내용을 현재 작업에 적용한다.

## 역할 바인딩

Orchestrator는 Planner, Implementer, Reviewer를 각각 별도의 비대화형 세션으로 호출한다. 계열과 모델에 관계없이 모든 역할 호출에 `codex exec` 또는 `claude -p`를 사용한다. 역할 프롬프트로 담당 작업의 범위와 검토 대상을 전달한다.

### 기본값과 호출 방법

| 역할 | 기본 계열 및 모델 | 기본 호출 방법 |
|---|---|---|
| Planner | Codex GPT-5.6 sol (max) | `codex exec --model gpt-5.6-sol -c model_reasoning_effort=max --sandbox read-only "{계획 프롬프트}"` |
| Implementer | Codex GPT-5.6 sol (max) | `codex exec --model gpt-5.6-sol -c model_reasoning_effort=max --sandbox workspace-write "{구현 프롬프트}"` |
| Reviewer | Claude Opus 4.8 (max) | `claude -p "{리뷰 프롬프트}" --model claude-opus-4-8 --effort max --output-format json --allowedTools "mcp__dokevy__*" --disallowedTools "Write,Edit,NotebookEdit,Bash"` |

* 사용자가 역할의 계열, 모델 또는 호출 방법을 지정하면 해당 값을 적용한다. 지정하지 않은 값에는 위 표의 기본값을 적용한다.
* Reviewer에는 Planner, Implementer와 다른 모델을 지정한다. Planner와 Implementer는 같은 모델을 사용할 수 있다.
* 모델 변경으로 Reviewer의 모델이 Planner 또는 Implementer와 같아지면 명령으로 지정하지 않은 역할의 모델을 변경한다.
* 사용자가 Reviewer와 다른 역할에 같은 모델을 지정하면 충돌을 설명하고 서로 다른 모델을 요청한다.
* 구현 작업은 하나의 Acceptance Criterion 또는 밀접하게 관련된 테스트 사례 묶음 단위로 위임한다.
* 기본 모델을 사용할 수 없으면 사용 가능한 다른 모델을 지정하고, 사용한 모델과 변경 사유를 결과에 기록한다.
* 사용자가 지정한 모델을 사용할 수 없으면 사유를 보고하고 대체 모델을 요청한다.

### Reviewer 호출

Reviewer 호출은 포그라운드에서 실행하고 완료될 때까지 기다린다. 셸 호출 제한 시간은 600000ms로 설정한다. 백그라운드에서 실행하지 않는다.

| 용도 | 명령 |
|---|---|
| Codex 리뷰 | `codex exec --model {model} --sandbox read-only "{리뷰 프롬프트}"` |
| Claude 리뷰 | `claude -p "{리뷰 프롬프트}" --model {model} --output-format json --allowedTools "mcp__dokevy__*" --disallowedTools "Write,Edit,NotebookEdit,Bash"` |

* 기존 세션 재개는 세션 ID 확보 규칙을 따른다.
* 리뷰 프롬프트에 리뷰 대상과 범위를 명시한다. 계획 리뷰는 이슈 본문을, 구현 가능성 리뷰는 작성 중인 diff를 지정한다. 코드 리뷰에서 Codex Reviewer는 `git diff {base}...HEAD` 비교 범위를 직접 읽는다. Bash가 차단된 Claude Reviewer에는 Orchestrator가 diff를 파일로 저장하고 그 경로를 전달한다.
* Codex의 `review` 서브커맨드를 사용하지 않는다. 이 서브커맨드는 `--base`와 프롬프트를 함께 받을 수 없다.

### 세션 저장소

* 세션 파일은 메인 워크트리 루트의 `.tmp/sessions/`에 저장한다.
* 메인 워크트리 루트는 `git rev-parse --path-format=absolute --git-common-dir` 결과의 부모 디렉터리로 정한다. 모든 워크트리에서 이 경로를 사용한다.
* 이슈 또는 Pull Request마다 파일 하나를 사용한다. 파일명은 `issue-171`, `pr-123` 형식으로 작성한다.
* `issue-*` 파일에는 `planner`와 이슈 리뷰용 `reviewer` 세션을 기록한다. 예: `{"planner": {"tool": "codex", "id": "{UUID}"}, "reviewer": {"tool": "claude", "id": "{UUID}"}}`.
* `pr-*` 파일에는 `implementer`와 Pull Request 리뷰용 `reviewer` 세션을 기록한다. 예: `{"implementer": {"tool": "codex", "id": "{UUID}"}, "reviewer": {"tool": "claude", "id": "{UUID}"}}`.
* 이전 역할 이름을 사용한 세션 키가 있으면 의미를 유지한 채 `implementer` 키로 이전한다.
* 이슈 리뷰용 Reviewer 세션과 Pull Request 리뷰용 Reviewer 세션은 서로 재개하지 않는다.
* Implementer 세션은 Pull Request를 생성한 시점에 `pr-*` 파일에 기록한다. 생성 전에는 `issue_implement`를 실행하는 Orchestrator 세션이 Implementer 세션 ID를 유지한다.
* `.tmp/sessions/`를 커밋하지 않는다.
* Orchestrator는 이슈가 닫히면 `issue-*` 파일을, Pull Request가 병합되거나 닫히면 `pr-*` 파일을 삭제한다.
* 세션 파일을 삭제하기 전에 파일에 기록된 Codex 세션을 `codex delete --force {UUID}`로 삭제한다. Claude에는 세션 삭제 명령이 없으므로 Claude 세션은 Claude Code의 자동 정리(기본 30일)에 맡긴다.

### 세션 ID 확보

Claude와 Codex 세션은 첫 호출에서 얻은 UUID로 재개한다.

* 첫 호출에서 세션 ID를 읽는다. Claude는 JSON 응답의 `session_id`, Codex는 출력 헤더의 `session id: {UUID}`를 사용한다. 세션 파일에 기록하는 시점은 세션 저장소 규칙을 따른다.
* 후속 호출에는 저장한 UUID를 전달한다. Codex는 호출 명령의 프롬프트 앞에 `resume {UUID}`를 넣고 `--sandbox`를 `resume` 앞에 둔다. Claude는 명령에 `--resume {UUID}`를 추가한다.
* Codex 세션을 이름으로 재개하지 않는다. 존재하지 않는 이름은 새 세션을 만들 수 있다.
* UUID로 재개하지 못하면 새 세션을 시작하고 세션 파일을 갱신한다.

### Orchestrator 세션

Orchestrator 세션은 저장하지 않는다. Orchestrator의 상태는 Dokevy 도구 반환 내용, 이슈와 Pull Request 본문, Issue Packet과 File Manifest로 재구성한다.

* 헤드리스 자동화에서는 같은 이슈 또는 Pull Request라도 작업마다 새 Orchestrator 세션을 시작한다. 해당 Dokevy 도구를 호출하고 반환된 지침을 포함한 프롬프트로 실행한다. Claude는 `claude -p --output-format json "{작업 프롬프트}"`, Codex는 `codex exec "{작업 프롬프트}"`를 사용한다.
* 대화형 세션과 remote-control 세션에서는 현재 세션에서 다음 작업을 실행한다.
* `issue_implement`가 반환한 구현과 리뷰 절차는 하나의 Orchestrator 세션에서 실행한다.
* 같은 대상에 여러 Orchestrator 세션을 동시에 사용하지 않는다.
