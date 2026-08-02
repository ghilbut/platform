# Rules for Agents

**[README.md](README.md) 파일을 참고해라.**

## Documentation

### Obsidian

* [docs/OBSIDIAN.md](docs/OBSIDIAN.md)를 따른다.
* Markdown 문서는 Properties, 상대 Markdown 링크, 섹션 링크를 사용한다.
* 항목 나열에는 문장, 목록, 테이블 중 목적에 맞는 형식을 사용하고 코드블록에는 backtick 세 개를 사용한다.

### Writing

* **게이트와 같은 모호한 표현을 금지한다.**
* 간결하고 명확하며 이해하기 쉬운 표현을 사용한다.
* 작업 범위에서 모순, 충돌, 모호함이 없는 상태를 유지한다.

## GitHub

* Branch 작업은 `.worktrees/` 디렉터리에서 한다.
* 작업은 PR을 만들어 리뷰를 받은 후 main에 병합한다.
* PR 병합은 정돈된 커밋 메세지와 함께 스쿼시 머지를 한다.
* 병합 후 작업 환경과 브랜치를 삭제하고 오리진과 로컬 메인을 동기화한다.
