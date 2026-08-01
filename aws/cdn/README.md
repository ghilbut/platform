# AWS CDN

`oidc.k3s.ghilbut.com`을 제공하는 CloudFront CDN OpenTofu 구성입니다.

## 구성

- S3 버킷: `ghilbut-cloudfront-cdn` (`us-east-1`)
- 상태 파일: `s3://ghilbut-tfstates/aws/cdn.tfstate`
- ACM 인증서: `ghilbut.com` 및 CDN 호스트의 SAN
- CloudFront: OAC를 통한 비공개 S3 원본
- Lambda@Edge: S3 객체 존재 여부 확인 및 SPA의 `index.html` 폴백
- CloudFront Function: 허용 호스트 검증, 리디렉션, URI 접두사 처리

Lambda는 루트 `pnpm-workspace.yaml`에 등록된 `@ghilbut/cdn-lambda` 워크스페이스
패키지입니다. 의존성 설치와 검사는 저장소 루트에서 `pnpm --filter
@ghilbut/cdn-lambda <script>`로 실행합니다.

기본 호스트는 파일 모드의 `oidc.k3s.ghilbut.com`입니다. 객체는
`s3://ghilbut-cloudfront-cdn/oidc.k3s.ghilbut.com/` 아래에 업로드합니다.

## 배포 전 준비

오류 페이지와 Lambda 아티팩트를 먼저 S3에 업로드해야 첫 `tofu apply`가
성공합니다. GitHub Actions는 `main` 브랜치에서 이 작업을 자동화합니다.

로컬에서 실행할 때는 `ghilbut-platform` AWS 프로필과 GitHub App 자격 증명이
필요합니다. GitHub App은 `ghilbut/platform`의 Actions variables를 수정할 수
있어야 합니다.

```sh
cd aws/cdn/tofu
export GITHUB_APP_ID=...
export GITHUB_APP_INSTALLATION_ID=...
export GITHUB_APP_PEM_FILE="$(cat /path/to/github-app.private-key.pem)"
tofu init
tofu apply
```

이 구성은 `AWS_IAM_ROLE_CDN_GITHUB_ACTIONS_ARN` 저장소 변수를 생성합니다.
Lambda 워크플로는 이 역할을 사용해 아티팩트를 올리고, 대상 리소스를 갱신합니다.

## GitHub Actions

- `aws-cdn-error-pages.yml`: `404.html`, `503.html`을 S3 버킷 루트에 업로드합니다.
- `aws-cdn-lambda.yml`: Lambda를 검사·빌드·업로드한 후 Lambda, CloudFront Function,
  CloudFront 배포를 갱신합니다.

두 워크플로 모두 `TOFU_GITHUB_APP_ID`, `TOFU_GITHUB_APP_INSTALLATION_ID`,
`TOFU_GITHUB_APP_PEM` 자격 증명과 위 역할 변수가 필요합니다.

## 호스트 추가

`tofu/variables.tf`의 `zones`에 호스트와 모드를 추가합니다.

```hcl
zones = {
  "ghilbut.com" = {
    "oidc.k3s" = { mode = "file" }
    "console"  = { mode = "spa" }
  }
}
```

지원 모드는 `file`, `spa`, `redirect`입니다. `redirect`에는 `redirect_host`를
지정해야 합니다.
