# OpenTofu Conventions

## Root 구성

- `versions.tf`에는 버전, backend, required providers만 둔다.
- `providers.tf`에는 provider와 root 공통 `default_tags`만 둔다.
- `variables.tf`, `outputs.tf`, `main.tf`는 입력, 외부 소비 output, 조합·리소스 선언으로
  구분한다.
- module도 이 파일 구분을 따르며, 수명 주기나 권한 경계가 없는 wrapper module은 만들지
  않는다.

## 상태 소유권

- `github/tofu`는 계정 공용 GitHub Actions OIDC provider만 관리한다.
- 서비스별 GitHub Actions IAM 역할은 그 서비스 root가 관리한다. GitHub repository variable은
  실행 Runbook에서 `gh variable set`으로 관리한다.
- 공용 OIDC provider ARN과 Foundation account ID처럼 root 사이에 필요한 식별자만
  `terraform_remote_state` output으로 소비한다. 한 리소스를 두 state에서 선언하지 않는다.
- backend key를 옮길 때는 `tofu init -migrate-state`로 state만 이전한다. 원격 리소스를
  삭제하거나 import로 다시 만들지 않는다.

## AWS CDN 태그와 이름

- CDN root provider `default_tags`는 `created_by`, `managed_by`, `project`, `service`,
  `opentofu/repo`, `opentofu/path`을 제공한다.
- CDN module은 `local.default_tags`에 `opentofu/module/repo`,
  `opentofu/module/path`만 추가한다. `var.default_tags`를 module input으로 전달하지
  않는다.
- CDN 리소스 이름과 `Name` 태그는 `cdn-platform`을 기준으로 한다. 저장소 소유자를
  중복한 `ghilbut-` 접두사는 S3의 전역 버킷 이름처럼 충돌 방지가 필요한 경우에만 쓴다.
- S3 객체에는 `Name` 태그를 붙이지 않는다. 객체 태그는 10개 제한을 넘지 않아야 한다.

## 의존성과 CI

- module output을 input으로 전달하면 별도 `depends_on`을 쓰지 않는다. output으로 표현할
  수 없는 의존성만 `depends_on`으로 선언한다.
- CDN CI는 `404.html`, `503.html`, `lambda.zip`, Lambda@Edge, CloudFront 배포판만
  대상으로 적용한다. IAM·DNS·ACM·CloudFront Function 변경은 로컬 apply의 책임이다.
- CDN OIDC 역할은 위 대상의 읽기·쓰기만 허용한다. 자기 자신 또는 Lambda 실행 역할의
  IAM 정책을 수정하는 권한을 부여하지 않는다.
- CI target 집합을 바꾸면 같은 target으로 `tofu plan -refresh-only`를 실행하고, 그
  호출에 필요한 읽기 권한만 정책에 추가한다.
