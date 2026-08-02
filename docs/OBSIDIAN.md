---
type: guide
area: documentation
---

# Obsidian 문서 규칙

## A. Properties

Markdown 문서는 YAML frontmatter에 type과 area를 기록한다.

## B. Links

문서 간 참조는 상대 Markdown 링크를 사용한다. 같은 문서의 섹션을 가리킬 때는 섹션 링크를 사용한다.

## C. Lists and tables

순서가 있는 작업은 숫자 목록으로, 독립적인 확인 항목은 불릿 목록으로, 항목과 값의 대응은 테이블로 작성한다.

## D. Code blocks

코드블록은 backtick 세 개를 사용한다.

## E. Templates and Bases

Templates는 [docs/obsidian/templates](obsidian/templates/) 폴더의 템플릿을 사용한다. 반복 실행 문서는 [RUN_PLAN](obsidian/templates/RUN_PLAN.md) 템플릿으로 만든다.

Bases는 Markdown Properties를 조회한다. 각 영역은 필요한 경우 해당 영역의 .base 파일로 문서 상태를 조회한다.
