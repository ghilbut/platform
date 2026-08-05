---
title: AWS architecture
---

# AWS

AWS 계정, OpenTofu root, 상태 소유권과 접근 경계를 정의한다. 실행 절차는
[AWS 운영 Runbook](RUNBOOK.md)을 따른다.

IAM Identity Center start URL은 `https://ghilbut.awsapps.com/start`이다.

## Accounts

| Account | ID | Email | Organization 위치 | 책임 |
|---|---|---|---|---|
| Management | `384959722788` | `aws@ghilbut.com` | Root | AWS Organizations, 계정 수명 주기와 IAM Identity Center |
| SharedServices | `012646747332` | `aws-platform@ghilbut.com` | Infrastructure OU | workload, 공용 state, CDN과 CI federation |
| Domains | `869061964712` | `aws-domains@ghilbut.com` | Infrastructure OU | Ghilbut 도메인 등록, Route 53와 DNS federation |
| UltaryDomains | `971119963968` | `aws-ultary-domains@ghilbut.com` | Root | Ultary 도메인 등록과 Route 53 |

## AWS Organizations

Organization `o-ncl6mypc8p`의 Root는 `r-k1tk`다. Root는 Infrastructure OU를 직접 포함한다.
Root에 연결한 `ProtectMemberAccounts` SCP는 모든 member account에 적용된다. 이 SCP는
`account:CloseAccount`와 `organizations:LeaveOrganization`을 거부한다. SCP는 Management
account에 적용되지 않는다.

| 위치 | 직접 포함하는 account | 연결 및 상속 |
|---|---|---|
| Root `r-k1tk` | Management, UltaryDomains | `FullAWSAccess`, `ProtectMemberAccounts` |
| Infrastructure `ou-k1tk-nmjtvc69` | Domains, SharedServices | `FullAWSAccess` 연결, `ProtectMemberAccounts` 상속 |

`FullAWSAccess`는 AWS 관리형 SCP다. AWS가 Root, OU와 account에 연결한 상태를 유지한다.

## Registered domains

- Domains: `ghilbut.com`, `ghilbut.net`
- UltaryDomains: `dokevy.com`, `dokevy.in`, `dokevy.io`, `dokevy.net`, `polykube.com`,
  `polykube.guide`, `polykube.in`, `polykube.io`, `polykube.net`, `ultary.co`,
  `ultary.guide`, `ultary.in`, `ultary.io`

## Directory responsibilities

| 경로 | 책임 |
|---|---|
| `cdn/` | SharedServices 계정의 CloudFront CDN과 배포 코드 |
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
| `foundation/identity/tofu/` | IAM Identity Center permission set, DevOps group, account assignment와 Management execution role |
| `foundation/identity/tofu/modules/permission-set/` | permission set, 정책 연결과 account assignment 조합 |
| `foundation/organizations/tofu/` | AWS Organization, OU, SCP와 delegated administrator |
| `shared-services/tofu/` | `ghilbut-tfstates`, SharedServices execution role과 CPA IAM OIDC provider |

Foundation에는 accounts, identity와 organizations 책임만 둔다. `organizations/tofu/`는 AWS
Organization, Infrastructure OU, SCP와 trusted access를 관리한다.

## State ownership

모든 active state는 SharedServices 계정의 versioned S3 bucket `ghilbut-tfstates`에 저장하고 같은
이름의 `.tflock` object를 사용한다. 하나의 resource는 하나의 state만 관리한다.

| Root | State key | Account | Plan source profile | Apply source profile |
|---|---|---|---|---|
| `aws/foundation/accounts/tofu/` | `platform/aws/foundation/accounts.tfstate` | Management | `ghilbut-tofu-plan-for-management` | `ghilbut-tofu-apply-for-management` |
| `aws/foundation/identity/tofu/` | `platform/aws/foundation/identity.tfstate` | Management | `ghilbut-tofu-plan-for-management` | `ghilbut-tofu-apply-for-management` |
| `aws/foundation/organizations/tofu/` | `platform/aws/foundation/organizations.tfstate` | Management | `ghilbut-tofu-plan-for-management` | `ghilbut-tofu-apply-for-management` |
| `aws/shared-services/tofu/` | `platform/aws/shared-services.tfstate` | SharedServices | `ghilbut-tofu-plan-for-workloads` | `ghilbut-tofu-apply-for-workloads` |
| `aws/cdn/tofu/` | `platform/aws/cdn.tfstate` | SharedServices | `ghilbut-tofu-plan-for-workloads` | `ghilbut-tofu-apply-for-workloads` |
| `apps/tofu/` | `platform/apps.tfstate` | SharedServices | `ghilbut-tofu-plan-for-workloads` | `ghilbut-tofu-apply-for-workloads` |
| `github/tofu/` | `platform/github.tfstate` | SharedServices | `ghilbut-tofu-plan-for-workloads` | `ghilbut-tofu-apply-for-workloads` |
| `k3s/tofu/` | `k3s.tfstate` | SharedServices | `ghilbut-tofu-plan-for-workloads` | `ghilbut-tofu-apply-for-workloads` |
| `domains/tofu/` | `platform/domains.tfstate` | Domains | `ghilbut-tofu-plan-for-domains` | `ghilbut-tofu-apply-for-domains` |
| `ultary/domains/tofu/` | `ultary/domains.tfstate` | UltaryDomains | `ghilbut-tofu-plan-for-ultary-domains` | `ghilbut-tofu-apply-for-ultary-domains` |

## Management access

Management console 책임과 Billing 책임은 서로 다른 permission set으로 관리한다.

| Permission set | Assignment | Source profile | Account-local role | 책임 |
|---|---|---|---|---|
| `FoundationManagement` | Management `384959722788` | `ghilbut-foundation-management` | 없음 | AWS Organizations, account와 IAM Identity Center 관리 |
| `Billing` | Management `384959722788` | `ghilbut-billing` | `arn:aws:iam::384959722788:role/billing` | Billing과 비용 관리 |

Management root user는 Billing account 설정에서 `Activate IAM access`를 한 번 활성화한다. 이
account 설정과 `Billing` permission set이 모두 적용되어야 IAM Identity Center 사용자가 Billing
Console을 열 수 있다.

## OpenTofu access

`TofuPlanFor*`와 `TofuApplyFor*`는 IAM Identity Center source identity다. Backend는 source
profile로 접근한다. Provider는 account-local `tofu-plan` 또는 `tofu-apply` execution role을
수임한다.

| Permission set | Assignment | Source profile | Account-local role | Role owner | 사용하는 root |
|---|---|---|---|---|---|
| `TofuPlanForManagement` | Management `384959722788` | `ghilbut-tofu-plan-for-management` | `arn:aws:iam::384959722788:role/tofu-plan` | `aws/foundation/identity/tofu/` | Foundation accounts, identity, organizations |
| `TofuApplyForManagement` | Management `384959722788` | `ghilbut-tofu-apply-for-management` | `arn:aws:iam::384959722788:role/tofu-apply` | `aws/foundation/identity/tofu/` | Foundation accounts, identity, organizations |
| `TofuPlanForWorkloads` | SharedServices `012646747332` | `ghilbut-tofu-plan-for-workloads` | `arn:aws:iam::012646747332:role/tofu-plan` | `aws/shared-services/tofu/` | SharedServices, CDN, apps, GitHub, K3s |
| `TofuApplyForWorkloads` | SharedServices `012646747332` | `ghilbut-tofu-apply-for-workloads` | `arn:aws:iam::012646747332:role/tofu-apply` | `aws/shared-services/tofu/` | SharedServices, CDN, apps, GitHub, K3s |
| `TofuPlanForDomains` | Domains `869061964712` | `ghilbut-tofu-plan-for-domains` | `arn:aws:iam::869061964712:role/tofu-plan` | `domains/tofu/` | Domains |
| `TofuApplyForDomains` | Domains `869061964712` | `ghilbut-tofu-apply-for-domains` | `arn:aws:iam::869061964712:role/tofu-apply` | `domains/tofu/` | Domains |
| `TofuPlanForUltaryDomains` | UltaryDomains `971119963968` | `ghilbut-tofu-plan-for-ultary-domains` | 없음 | 없음 | UltaryDomains |
| `TofuApplyForUltaryDomains` | UltaryDomains `971119963968` | `ghilbut-tofu-apply-for-ultary-domains` | 없음 | 없음 | UltaryDomains |

`TofuPlanForWorkloads`와 `TofuApplyForWorkloads`는 workload 운영 계정이 공유한다. 현재
assignment는 SharedServices `012646747332` 하나다. Domains permission set은 Domains account에만
할당한다. `FoundationManagement`와 `Billing`은 OpenTofu source profile로 사용하지 않는다.

Plan source identity는 `.tfstate`를 읽고 해당 `.tflock`을 읽고 쓰고 삭제한다. Apply source
identity는 해당 `.tfstate`와 `.tflock`을 읽고 쓰고 삭제한다. `tofu-plan` role은 managed
resource를 읽으며 `tofu-apply` role은 managed resource를 변경한다. UltaryDomains는 account-local
execution role 없이 source identity를 provider에서 직접 사용한다.

Permission set session duration과 account-local role의 configured maximum session duration은
4시간이다. SSO role이 account-local role을 수임하면 IAM role chaining에 따라 execution role
session은 최대 1시간이다.

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
- Organizations `FullAWSAccess` SCP
- Organizations, IAM Identity Center, Support, Trusted Advisor와 Service Quotas service-linked role
- Lambda replicator와 CloudFront logger service-linked role
- Athena primary workgroup과 catalog
- EventBridge default bus와 X-Ray default sampling rule
- RDS, ElastiCache, MemoryDB와 App Runner default resource
- S3 Storage Lens default dashboard

Domains customer-managed KMS key `6ebc75ad-c084-4c1a-842e-b45482e5e668`의 상태는
`PendingDeletion`이고 예약 삭제 시각은 `2026-09-04T01:16:50.578+09:00`이다. 실제 삭제는
예약 시각보다 최대 24시간 늦을 수 있으며 AWS KMS가 완료한다.
