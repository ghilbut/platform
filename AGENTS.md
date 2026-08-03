# Rules for Agents

**[README.md](README.md) 파일을 참고해라.**

## Documentation

### Obsidian

* 모든 마크다운 문서 포맷은 Obsidian의 기능과 장점을 최대한 활용할 수 있도록 최적화한다.
* 코드블록은 backtick 세 개를 사용한다.
* Rulebook은 `knowledge/rulebooks/` 디렉토리에 작성한다.
* Runbook과 Playbook은 대상과 가까운 곳에 작성한다.
* 레퍼런스 Runbook과 실제 실행 Runbook이 함께 필요하다면,
  * RUNBOOK.md를 레퍼런스 문서로 작성하고
  * runbooks/{name}.md를 실행 문서로 작성한다.

### Writing

* **게이트와 같은 모호한 표현을 금지한다.**
* 내용을 항상 간결하고 명확하며 고등학생 수준에서 이해하기 쉽게 유지한다.
* 작업 범위에서 모순, 충돌, 모호함이 없는 상태를 유지한다.
* 표준 표현을 사용하고, 동일한 대상에 대하여 언제나 같은 표기를 사용한다.
* 긍정 단언과 강한 부정 표현만을 사용한다.
* 절대 참과 절대 거짓은 제거한다.
* 과거 이력 등을 설명하지 않는다.

## GitHub

* Branch 작업은 `.worktrees/` 디렉터리에서 한다.
* 작업은 PR을 만들어 리뷰를 받은 후 main에 병합한다.
* 여러 개의 작업으로 나눠야 한다면 parent/sub-issue 형태로 분할한다.
* 하나의 Issue에는 하나의 PR만 연결한다.
* PR 병합은 정돈된 커밋 메세지와 함께 스쿼시 머지를 한다.
* 병합 후 작업 환경과 브랜치를 삭제하고 오리진과 로컬 메인을 동기화한다.
