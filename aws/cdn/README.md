# AWS CDN

`oidc.k3s.ghilbut.com`을 제공하는 CloudFront CDN OpenTofu 구성입니다.

## 구성

- S3 버킷: `ghilbut-platform-cdn` (`us-east-1`)
- 상태 파일: `s3://ghilbut-tfstates/aws/cdn.tfstate`
- ACM 인증서: `ghilbut.com` 및 CDN 호스트의 SAN
- CloudFront: OAC를 통한 비공개 S3 원본

S3 객체는 최대 10개 태그를 지원합니다. 현재 기본·루트·모듈 출처 태그 8개를 적용합니다.
- Lambda@Edge: S3 객체 존재 여부 확인 및 SPA의 `index.html` 폴백
- CloudFront Function: 허용 호스트 검증, 리디렉션, URI 접두사 처리

Lambda는 루트 `pnpm-workspace.yaml`에 등록된 `@ghilbut/cdn-lambda` 워크스페이스
패키지입니다. 의존성 설치와 검사는 저장소 루트에서 `pnpm --filter
@ghilbut/cdn-lambda <script>`로 실행합니다.

기본 호스트는 파일 모드의 `oidc.k3s.ghilbut.com`입니다. 객체는
`s3://ghilbut-platform-cdn/oidc.k3s.ghilbut.com/` 아래에 업로드합니다.

`k3s/tofu/`는 `cpa` kubectl 컨텍스트의 OIDC 문서를 다음 S3 객체로 동기화합니다.
discovery 문서의 `issuer`와 `jwks_uri`는 공개 CDN URL로 재작성됩니다.

- `oidc.k3s.ghilbut.com/cpa/openid/v1/jwks`
- `oidc.k3s.ghilbut.com/cpa/.well-known/openid-configuration`

## 배포 전 준비

오류 페이지와 Lambda ZIP은 OpenTofu가 S3 객체로 관리합니다. 로컬 첫 배포 전에는
Lambda 번들만 빌드하면 됩니다.

로컬에서 실행할 때는 `ghilbut-platform` AWS 프로필과 `GH_TOKEN` fine-grained
PAT가 필요합니다. PAT에는 `ghilbut/platform`의 Variables 읽기·쓰기 권한이
필요합니다. 첫 배포 전에는 공유 GitHub Actions OIDC provider를
[`github/tofu/`](../../github/tofu/)에서 먼저 적용해야 합니다. CDN 구성은
`platform/github.tfstate`의 `github_actions_oidc_provider_arn` 출력을 참조합니다.

```sh
cd github/tofu
tofu init
tofu apply

cd ../..
pnpm --filter @ghilbut/cdn-lambda build
cd aws/cdn/tofu
export AWS_PROFILE=ghilbut-platform
export GITHUB_TOKEN="$GH_TOKEN"
tofu init
tofu apply
```

이 구성은 `AWS_IAM_ROLE_CDN_GITHUB_ACTIONS_ARN` 저장소 변수를 생성합니다.
Lambda 워크플로는 이 역할을 사용해 기존 CDN의 Lambda·오류 페이지·CloudFront
갱신과 연결된 inline policy 갱신만 수행합니다.

## GitHub Actions

- `aws-cdn-lambda.yml`: Lambda를 검사·빌드한 뒤 오류 페이지, Lambda ZIP, Lambda,
  CloudFront Function, CloudFront 배포를 OpenTofu로 갱신합니다.

워크플로는 GitHub가 발급하는 `GITHUB_TOKEN`으로 repository variable을 관리하며,
`actions: write` 권한과 위 역할 변수가 필요합니다.

S3 버킷, ACM 인증서, CloudFront 배포, IAM 역할, Route53 레코드의 생성·교체·삭제와
IAM trust policy 변경은 워크플로 범위 밖입니다. 이런 OpenTofu 구성 변경은
`ghilbut-platform` 프로필로 로컬에서 apply합니다.

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
