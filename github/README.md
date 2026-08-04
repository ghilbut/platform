# GitHub

이 디렉터리는 GitHub와 연동되는 플랫폼 인프라 구성을 관리합니다.

## GitHub Actions OIDC

`tofu/`는 Platform 계정에서 공유하는 GitHub Actions OIDC provider를 관리합니다.
provider URL은 `https://token.actions.githubusercontent.com`이고, 허용 audience는
`sts.amazonaws.com`입니다.

AWS 계정에서는 같은 OIDC provider URL을 하나만 등록할 수 있습니다. 따라서 provider는
여기에서 한 번만 관리하고, CDN 같은 개별 서비스 구성은 `platform/github.tfstate`의 output을
읽어 전용 IAM 역할을 만듭니다.

각 서비스 역할은 다음을 직접 관리해야 합니다.

- 필요한 AWS 권한만 포함한 정책
- `repository`, `branch`, `tag`, `environment` 등으로 제한한 trust policy 조건

이 분리는 CDN을 변경하거나 제거해도 다른 서비스의 GitHub Actions 신뢰 기반에 영향을
주지 않게 합니다.

## 배포

GitHub Actions OIDC를 처음 사용하는 서비스보다 먼저 적용합니다.

```sh
cd github/tofu
tofu init
tofu apply
```

OpenTofu 상태는 `s3://ghilbut-tfstates-v2/platform/github.tfstate`에 저장되며,
`ghilbut-tofu-apply-for-workloads` AWS 프로필을 사용합니다.
