# Platform

## A. AI Agents

### Claude Remote-Control

[**claude-rc.sh**](claude-rc.sh)

## B. Directories

각 리소스는 하나의 OpenTofu 상태만 관리한다.

| 경로                                        | 책임                                                                                |
|---------------------------------------------|-------------------------------------------------------------------------------------|
| `apps/`                                     | 인프라와 플랫폼을 관리하는 어플리케이션들                                           |
| [aws/](aws/README.md)                       | AWS 계정, 접근 권한과 Platform 서비스                                                |
| `domains/`                                  | 도메인과 DNS 서버 관리                                                              |
| `github/`                                   | Github 계정 관리                                                                    |
| `k3s/`                                      | 온프레미스 K3s 관리 및 클라우드 연동                                                |
| `pki/`                                      | Root CA 인증서와 Intermediate 인증서의 작업 공간. 인증서는 git과 동기화하지 않는다. |
| `ultary/`                                   | `Ultary, Inc.`가 준비될 때까지 일부 관리를 대신해 준다.                             |

## C. Programming

### OpenTofu

OpenTofu 작성·상태·배포 지침은 [[knowledge/rulebooks/TOFU|OpenTofu Rulebook]]을 따른다.
