# Platform

## Directories

각 리소스는 하나의 OpenTofu 상태만 관리한다.

| 경로 | 책임 | 소유하지 않는 것 |
| --- | --- | --- |
| `.github/workflows/` | 저장소 CI와 배포 절차 | 인프라의 영구 상태 |
| `aws/identity/tofu/` | AWS IAM Identity Center와 조직 계정 기반 | 다른 AWS 서비스 리소스 |
| `aws/cdn/` | CDN 애플리케이션 산출물과 CDN 인프라 | 계정 공용 GitHub OIDC provider |
| `aws/cdn/tofu/` | CDN, 배포 역할, `AWS_IAM_ROLE_CDN_GITHUB_ACTIONS_ARN` 저장소 변수 | 다른 서비스의 GitHub 변수와 역할 |
| `github/tofu/` | AWS 계정 공용 GitHub Actions OIDC provider | 서비스별 IAM 역할, 저장소 변수, CDN 리소스 |
| `k3s/tofu/` | K3S 공개 OIDC 문서를 CDN S3 원본에 동기화 | CDN 배포판, 버킷, GitHub Actions 역할 |
| `.worktrees/` | 브랜치 작업용 Git worktree | 영구 소스 또는 상태 파일 |

`github/tofu/`는 재사용 가능한 GitHub Actions OIDC provider 하나만 관리한다.
`aws/cdn/tofu/`는 그 provider ARN을 읽어 CDN 전용 역할과 저장소 변수를 관리한다.

OpenTofu 작성·상태·배포 지침은 [docs/TOFU.md](docs/TOFU.md)를 따른다.

## Claude Remote-Control

[**claude-rc.sh**](claude-rc.sh)

```shell
$ ANTHROPIC_MODEL=claude-opus-4-8 \
  CLAUDE_CODE_EFFORT_LEVEL=xhigh \
  claude \
  remote-control \
  --remote-control-session-name-prefix "ghilbut" \
  --permission-mode bypassPermissions \
  --spawn worktree \
  --capacity 4 \
  --no-create-session-in-dir
```

## Accounts

### AWS

SSO Start URL: https://ghilbut.awsapps.com/start

| ID           | Name           | Email                          |
|--------------|----------------|--------------------------------|
| 384959722788 | management     | aws@ghilbut.com                |
| 869061964712 | platform       | aws-platform@ghilbut.com       |
| 971119963968 | ultary-domains | aws-ultary-domains@ghilbut.com |

## Domains

### Ghilbut

* ghilbut.com
* ghilbut.net

### Ultary, Inc.

* dokevy.com
* dokevy.io
* dokevy.net
* polykube.com
* polykube.io
* polykube.net
* ultary.co
* ultary.io
