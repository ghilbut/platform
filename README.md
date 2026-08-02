# Platform

## A. AI Agents

### Claude Remote-Control

[**claude-rc.sh**](claude-rc.sh)

## B. Directories

각 리소스는 하나의 OpenTofu 상태만 관리한다.

| 경로 | 책임 |
|---|---|
| `apps/` | 인프라와 플랫폼을 관리하는 어플리케이션들 |
| `aws/` | AWS 관리 그룹 디렉토리 |
| `aws/accounts/` | AWS Organizations 계정 |
| `aws/identity/` | AWS IAM Identity Center 관리 |
| `aws/management/` | AWS 관리 계정의 접근 제한과 opt-in 리전 설정 |
| `aws/cdn/` | AWS CloudFront 기반의 CDN 인프라와 어플리케이션 |
| `docs/` | 참고 문서 |
| `domains/` | 도메인과 DNS 서버 관리 |
| `github/` | Github 계정 관리 |
| `k3s/` | 온프레미스 K3s 관리 및 클라우드 연동 |
| `pki/` | Root CA 인증서와 Intermediate 인증서의 작업 공간. 인증서는 git과 동기화하지 않는다. |
| `ultary/` | `Ultary, Inc.`가 준비될 때까지 일부 관리를 대신해 준다. |

## C. Programming

### OpenTofu

OpenTofu 작성·상태·배포 지침은 [docs/TOFU.md](docs/TOFU.md)를 따른다.

## D. Accounts

### AWS

SSO Start URL: https://ghilbut.awsapps.com/start

| ID           | Name           | Email                          |
|--------------|----------------|--------------------------------|
| 384959722788 | management     | aws@ghilbut.com                |
| 869061964712 | platform       | aws-platform@ghilbut.com       |
| 971119963968 | ultary-domains | aws-ultary-domains@ghilbut.com |

## E. Domains

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
