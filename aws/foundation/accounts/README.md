---
title: AWS Foundation 계정
---

# AWS Foundation 계정

`tofu/`는 AWS Organizations 계정 수명 주기와 관리 계정의 opt-in 리전 설정을 관리한다.

상태 backend key는 `platform/aws/foundation/accounts.tfstate`다. 기존
`platform/aws/accounts.tfstate` 상태를 이전할 때는 새 경로의 `tofu/`에서 다음 명령을 실행한다.

```sh
tofu init -migrate-state
```

리소스를 새로 만들거나 import하지 않는다. OpenTofu 작업 절차는
[OpenTofu 규칙](../../../docs/TOFU.md)을 따른다.
