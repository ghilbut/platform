---
title: AWS architecture
---

# AWS

AWS 계정, OpenTofu root, 상태 소유권과 접근 경계를 정의한다. 실행 절차는
[AWS 운영 Runbook](RUNBOOK.md)을 따른다.

IAM Identity Center start URL은 `https://ghilbut.awsapps.com/start`이다.

## Accounts

| Account | ID | Email | 책임 |
|---|---|---|---|
| Management | `384959722788` | `aws@ghilbut.com` | AWS Organizations, 계정 수명 주기와 IAM Identity Center |
| Platform | `012646747332` | `aws-platform@ghilbut.com` | workload, 공용 state, CDN과 CI federation |
| Domains | `869061964712` | `aws-domains@ghilbut.com` | Ghilbut 도메인 등록, Route 53와 DNS federation |
| UltaryDomains | `971119963968` | `aws-ultary-domains@ghilbut.com` | Ultary 도메인 등록과 Route 53 |

## Registered domains

- Domains: `ghilbut.com`, `ghilbut.net`
- UltaryDomains: `dokevy.com`, `dokevy.in`, `dokevy.io`, `dokevy.net`, `polykube.com`,
  `polykube.guide`, `polykube.in`, `polykube.io`, `polykube.net`, `ultary.co`,
  `ultary.guide`, `ultary.in`, `ultary.io`

## Directory responsibilities

| 경로 | 책임 |
|---|---|
| `cdn/` | Platform 계정의 CloudFront CDN과 배포 코드 |
| `cdn/lambda/` | S3 원본 확인과 SPA fallback을 처리하는 Lambda@Edge 소스와 테스트 |
| `cdn/tofu/` | S3, ACM, Lambda@Edge, CloudFront, OAC와 GitHub Actions IAM role |
| `cdn/tofu/modules/certificate/` | ACM certificate와 DNS validation output |
| `cdn/tofu/modules/cloudfront/` | CloudFront distribution과 function |
| `cdn/tofu/modules/edge/` | Lambda bundle object, 실행 role과 Lambda@Edge function |
| `cdn/tofu/modules/github-actions/` | CDN 배포용 GitHub Actions role |
| `cdn/tofu/modules/origin-access/` | CloudFront OAC |
| `cdn/tofu/modules/s3/` | 비공개 CDN origin bucket과 object |
| `foundation/` | accounts, identity와 organizations 책임 경계 |
| `foundation/accounts/tofu/` | AWS Organizations account와 Management account opt-in region |
| `foundation/accounts/tofu/modules/management/` | Management account의 Account Management API 호출 |
| `foundation/identity/tofu/` | IAM Identity Center permission set, DevOps group, account assignment와 Management `tofu-apply` role |
| `foundation/identity/tofu/modules/permission-set/` | permission set, 정책 연결과 account assignment 조합 |
| `platform/tofu/` | `ghilbut-tfstates`, Platform `tofu-apply` role과 CPA IAM OIDC provider |

Foundation에는 accounts, identity와 organizations 책임만 둔다. `organizations/tofu/`는 OU,
SCP와 delegated administrator를 관리하는 root로 추가한다.

## State ownership

모든 active state는 Platform 계정의 versioned S3 bucket `ghilbut-tfstates`에 저장하고 같은
이름의 `.tflock` object를 사용한다. 하나의 resource는 하나의 state만 관리한다.

| Root | State key | Account | Source profile |
|---|---|---|---|
| `aws/foundation/accounts/tofu/` | `platform/aws/foundation/accounts.tfstate` | Management | `ghilbut-tofu-apply-for-management` |
| `aws/foundation/identity/tofu/` | `platform/aws/foundation/identity.tfstate` | Management | `ghilbut-tofu-apply-for-management` |
| `aws/platform/tofu/` | `platform/aws/platform.tfstate` | Platform | `ghilbut-tofu-apply-for-workloads` |
| `aws/cdn/tofu/` | `platform/aws/cdn.tfstate` | Platform | `ghilbut-tofu-apply-for-workloads` |
| `apps/tofu/` | `platform/apps.tfstate` | Platform | `ghilbut-tofu-apply-for-workloads` |
| `github/tofu/` | `platform/github.tfstate` | Platform | `ghilbut-tofu-apply-for-workloads` |
| `k3s/tofu/` | `k3s.tfstate` | Platform | `ghilbut-tofu-apply-for-workloads` |
| `domains/tofu/` | `platform/domains.tfstate` | Domains | `ghilbut-tofu-apply-for-domains` |
| `ultary/domains/tofu/` | `ultary/domains.tfstate` | UltaryDomains | `ghilbut-tofu-apply-for-ultary-domains` |

## OpenTofu access

`TofuApplyFor*`는 IAM Identity Center source identity다. `tofu-apply`는 각 계정 안에서
OpenTofu가 수임하는 execution role이다. Backend는 source profile로 접근한다.

| Permission set | Assignment | Source profile | Account-local `tofu-apply` | Role owner | 사용하는 root |
|---|---|---|---|---|---|
| `TofuApplyForManagement` | Management `384959722788` | `ghilbut-tofu-apply-for-management` | `arn:aws:iam::384959722788:role/tofu-apply` | `aws/foundation/identity/tofu/` | Foundation accounts, identity |
| `TofuApplyForWorkloads` | Platform `012646747332` | `ghilbut-tofu-apply-for-workloads` | `arn:aws:iam::012646747332:role/tofu-apply` | `aws/platform/tofu/` | Platform, CDN, apps, GitHub, K3s |
| `TofuApplyForDomains` | Domains `869061964712` | `ghilbut-tofu-apply-for-domains` | `arn:aws:iam::869061964712:role/tofu-apply` | `domains/tofu/` | Domains |
| `TofuApplyForUltaryDomains` | UltaryDomains `971119963968` | `ghilbut-tofu-apply-for-ultary-domains` | 없음 | 없음 | UltaryDomains |

`TofuApplyForWorkloads`는 Platform account에만 할당한다. `TofuApplyForDomains`는 Domains
account에만 할당한다. `FoundationManagement`는 Management console 관리용 permission set이며
OpenTofu source profile로 사용하지 않는다.

`aws/platform/tofu/`는 Platform `tofu-apply` role과 CPA OIDC provider를 source profile로
직접 관리한다. 같은 root의 S3 resource는 `aws.platform` provider alias로 Platform
`tofu-apply` role을 수임한다. `apps/tofu/`, `k3s/tofu/`와 UltaryDomains는 source identity를
provider에서 직접 사용한다.

## CDN

`aws/cdn/tofu/`는 `ghilbut-cdn-platform` bucket과
`oidc.k3s.ghilbut.com` CloudFront distribution을 관리한다. 기본 host mode는 `file`이다.
`zones` input은 `file`, `spa`, `redirect` mode를 지원하며 `redirect`는 `redirect_host`를
지정한다.
K3s root는 다음 CPA OIDC object를 origin bucket에 동기화한다.

- `oidc.k3s.ghilbut.com/cpa/.well-known/openid-configuration`
- `oidc.k3s.ghilbut.com/cpa/openid/v1/jwks`

GitHub Actions는 오류 페이지, Lambda bundle, Lambda@Edge와 CloudFront 배포만 갱신한다.
S3 bucket, ACM certificate, CloudFront Function, IAM role과 Route 53 변경은 로컬 OpenTofu가
관리한다.

## AWS-managed resources

AWS가 생성하고 관리하는 KMS alias, service-linked role과 default resource는 유지한다.
OpenTofu state에 import하거나 삭제하지 않는다. 대상에는 다음 resource가 포함된다.

- `alias/aws/acm`, `alias/aws/lambda`
- Organizations, IAM Identity Center, Support, Trusted Advisor와 Service Quotas service-linked role
- Lambda replicator와 CloudFront logger service-linked role
- Athena primary workgroup과 catalog
- EventBridge default bus와 X-Ray default sampling rule
- RDS, ElastiCache, MemoryDB와 App Runner default resource
- S3 Storage Lens default dashboard

Domains customer-managed KMS key `6ebc75ad-c084-4c1a-842e-b45482e5e668`의 상태는
`PendingDeletion`이고 예약 삭제 시각은 `2026-09-04T01:16:50.578+09:00`이다. 실제 삭제는
예약 시각보다 최대 24시간 늦을 수 있으며 AWS KMS가 완료한다.
