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
| SecurityTooling | `954066442429` | `aws-security-tooling@ghilbut.com` | Security OU | 보안 도구와 보안 운영 workload |
| UltaryDomains | `971119963968` | `aws-ultary-domains@ghilbut.com` | Root | Ultary 도메인 등록과 Route 53 |

## AWS Organizations

Organization `o-ncl6mypc8p`의 Root는 `r-k1tk`다. Root는 Infrastructure OU와 Security OU를
직접 포함한다. Root에 연결한 `ProtectMemberAccounts` SCP는 모든 member account에 적용된다.
이 SCP는 `account:CloseAccount`와 `organizations:LeaveOrganization`을 거부한다. SCP는
Management account에 적용되지 않는다.

| 위치 | 직접 포함하는 account | 연결 및 상속 |
|---|---|---|
| Root `r-k1tk` | Management, UltaryDomains | `FullAWSAccess`, `ProtectMemberAccounts` |
| Infrastructure `ou-k1tk-nmjtvc69` | Domains, SharedServices | `FullAWSAccess` 연결, `ProtectMemberAccounts` 상속 |
| Security `ou-k1tk-rx2wvnws` | SecurityTooling | `FullAWSAccess` 연결, `ProtectMemberAccounts` 상속 |

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
| `cdn/tofu/` | S3, ACM, Lambda@Edge, CloudFront와 OAC |
| `cdn/tofu/modules/certificate/` | ACM certificate와 DNS validation output |
| `cdn/tofu/modules/cloudfront/` | CloudFront distribution과 function |
| `cdn/tofu/modules/edge/` | Lambda bundle object, 실행 role과 Lambda@Edge function |
| `cdn/tofu/modules/origin-access/` | CloudFront OAC |
| `cdn/tofu/modules/s3/` | 비공개 CDN origin bucket과 object |
| `foundation/` | accounts, identity와 organizations 책임 경계 |
| `foundation/accounts/tofu/` | AWS Organizations account와 account별 opt-in region |
| `foundation/accounts/tofu/modules/account-regions/` | account별 Account Management Region API 호출 |
| `foundation/identity/tofu/` | IAM Identity Center permission set, DevOps group, account assignment와 Management execution role |
| `foundation/identity/tofu/modules/permission-set/` | permission set, 정책 연결과 account assignment 조합 |
| `foundation/organizations/tofu/` | AWS Organization, OU, SCP와 delegated administrator |
| `security-tooling/tofu/` | SecurityTooling 계정의 OpenTofu Plan과 Apply execution role |
| `shared-services/tofu/` | `ghilbut-tfstates`, 중앙 state role, `tofu-state-admin`, `deployer`, SharedServices execution role, GitHub Actions와 CPA IAM OIDC provider |

Foundation에는 accounts, identity와 organizations 책임만 둔다. `organizations/tofu/`는 AWS
Organization, Infrastructure OU, Security OU, SCP와 trusted access를 관리한다.

## State ownership

모든 active state는 SharedServices 계정의 versioned S3 bucket `ghilbut-tfstates`에 저장하고 같은
이름의 `.tflock` object를 사용한다. 하나의 resource는 하나의 state만 관리한다.

모든 backend의 기본 역할은 SharedServices `tofu-state-readonly`다. 이 역할은 active `.tfstate`를
읽고 대응하는 `.tflock`을 읽고 쓰고 삭제한다. Apply backend는 로컬 `.tfbackend` 설정으로
SharedServices `tofu-state-apply`를 수임한다. 이 역할은 active `.tfstate`와 `.tflock`을 읽고 쓰고
삭제한다. 두 역할은 recovery state와 `ghilbut-tfstates-v2`에 접근하지 않는다.

`platform/aws/shared-services/state.tfstate`는 state bucket 전용 root에 사용할 예약 key다. 중앙
state role은 이 key와 대응하는 lock key에 접근할 수 있다. State bucket 리소스는 아직
`aws/shared-services/tofu/`의 `platform/aws/shared-services.tfstate`가 소유한다.

| Root | State key | Account | Plan source profile | Apply source profile |
|---|---|---|---|---|
| `aws/foundation/accounts/tofu/` | `platform/aws/foundation/accounts.tfstate` | Management | `ghilbut-tofu-plan-for-management` | `ghilbut-tofu-apply-for-management` |
| `aws/foundation/identity/tofu/` | `platform/aws/foundation/identity.tfstate` | Management | `ghilbut-tofu-plan-for-management` | `ghilbut-tofu-apply-for-management` |
| `aws/foundation/organizations/tofu/` | `platform/aws/foundation/organizations.tfstate` | Management | `ghilbut-tofu-plan-for-management` | `ghilbut-tofu-apply-for-management` |
| `aws/shared-services/tofu/` | `platform/aws/shared-services.tfstate` | SharedServices | `ghilbut-tofu-plan-for-workloads` | `ghilbut-tofu-apply-for-workloads` |
| `aws/security-tooling/tofu/` | `platform/aws/security-tooling.tfstate` | SecurityTooling | `ghilbut-tofu-plan-for-security-tooling` | `ghilbut-tofu-apply-for-security-tooling` |
| `aws/cdn/tofu/` | `platform/aws/cdn.tfstate` | SharedServices | `ghilbut-tofu-plan-for-workloads` | `ghilbut-tofu-apply-for-workloads` |
| `apps/tofu/` | `platform/apps.tfstate` | SharedServices | `ghilbut-tofu-plan-for-workloads` | `ghilbut-tofu-apply-for-workloads` |
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

`TofuPlanFor*`와 `TofuApplyFor*`는 IAM Identity Center source identity다. 하나의 source
profile을 backend와 provider가 함께 사용한다. Backend는 SharedServices의 중앙 state role을
수임하고 provider는 대상 account의 `tofu-plan` 또는 `tofu-apply` execution role을 수임한다.

| Permission set | Assignment | Source profile | Account-local role | Role owner | 사용하는 root |
|---|---|---|---|---|---|
| `TofuPlanForManagement` | Management `384959722788` | `ghilbut-tofu-plan-for-management` | `arn:aws:iam::384959722788:role/tofu-plan` | `aws/foundation/identity/tofu/` | Foundation accounts, identity, organizations |
| `TofuApplyForManagement` | Management `384959722788` | `ghilbut-tofu-apply-for-management` | `arn:aws:iam::384959722788:role/tofu-apply` | `aws/foundation/identity/tofu/` | Foundation accounts, identity, organizations |
| `TofuPlanForWorkloads` | SharedServices `012646747332` | `ghilbut-tofu-plan-for-workloads` | `arn:aws:iam::012646747332:role/tofu-plan` | `aws/shared-services/tofu/` | SharedServices, CDN, apps, GitHub, K3s |
| `TofuApplyForWorkloads` | SharedServices `012646747332` | `ghilbut-tofu-apply-for-workloads` | `arn:aws:iam::012646747332:role/tofu-apply` | `aws/shared-services/tofu/` | SharedServices, CDN, apps, GitHub, K3s |
| `TofuPlanForWorkloads` | SecurityTooling `954066442429` | `ghilbut-tofu-plan-for-security-tooling` | `arn:aws:iam::954066442429:role/tofu-plan` | `aws/security-tooling/tofu/` | SecurityTooling |
| `TofuApplyForWorkloads` | SecurityTooling `954066442429` | `ghilbut-tofu-apply-for-security-tooling` | `arn:aws:iam::954066442429:role/tofu-apply` | `aws/security-tooling/tofu/` | SecurityTooling |
| `TofuPlanForDomains` | Domains `869061964712` | `ghilbut-tofu-plan-for-domains` | `arn:aws:iam::869061964712:role/tofu-plan` | `domains/tofu/` | Domains |
| `TofuApplyForDomains` | Domains `869061964712` | `ghilbut-tofu-apply-for-domains` | `arn:aws:iam::869061964712:role/tofu-apply` | `domains/tofu/` | Domains |
| `TofuPlanForUltaryDomains` | UltaryDomains `971119963968` | `ghilbut-tofu-plan-for-ultary-domains` | 없음 | 없음 | UltaryDomains |
| `TofuApplyForUltaryDomains` | UltaryDomains `971119963968` | `ghilbut-tofu-apply-for-ultary-domains` | 없음 | 없음 | UltaryDomains |

`TofuPlanForWorkloads`와 `TofuApplyForWorkloads`는 workload 운영 계정이 공유한다. 현재
assignment는 SharedServices `012646747332`와 SecurityTooling `954066442429`이다. Domains
permission set은 Domains account에만 할당한다. `FoundationManagement`와 `Billing`은 OpenTofu
source profile로 사용하지 않는다.

이 문서에서 workload account는 Workloads permission set을 공유하는 SharedServices와
SecurityTooling이다. Management는 Foundation 전용 account이며 Domains와 UltaryDomains는 DNS
전용 account다.

Workloads permission set과 `deployer`는 인증 후 execution role을 수임하는 source identity다.
두 source identity는 workload resource를 직접 관리하지 않는다. 각 workload account의
`tofu-plan`과 `tofu-apply`가 최종 인가를 제공한다. `tofu-plan`은 `ReadOnlyAccess`를 사용하고
`tofu-apply`는 `PowerUserAccess`, `IAMFullAccess`와 중앙 관리 기능 거부 정책을 사용한다. 모든
workload account에 같은 정책을 적용하며 account별 resource 정책을 추가하지 않는다.
`tofu-plan`과 `tofu-apply`는 `ghilbut-tfstates`와 `ghilbut-tfstates-v2`의 객체에 직접 접근하지
못한다. `tofu-apply`는 두 state bucket의 객체를 만료시키는 lifecycle 설정도 적용하지 못한다.

SharedServices `deployer`는 Management, SharedServices, SecurityTooling과 Domains의
`tofu-plan`·`tofu-apply`, `tofu-state-admin` 및 공용 state role을 수임한다. 현재 GitHub OIDC가 이
role에 로그인하며 향후 Tekton도 같은 role을 사용한다. UltaryDomains는 별도 운영 계정이므로
포함하지 않는다.
단일 source role의 범위는 각 target role 정책과 GitHub main branch OIDC 조건으로 제한한다.

Plan source identity는 `tofu-state-readonly`와 matching `tofu-plan`만 수임한다. Apply source
identity는 `tofu-state-apply`, remote state 읽기용 `tofu-state-readonly`와 matching `tofu-apply`를
수임한다. 모든 source identity는 `ghilbut-tfstates` 직접 접근이 거부된다. `tofu-plan` role은
workload resource를 읽으며 `tofu-apply` role은 workload resource를 변경한다. UltaryDomains는
account-local execution role 없이 source identity를 provider에서 직접 사용한다.

Role-backed root의 `aws_execution_role_arn` 기본값은 account-local `tofu-plan` role이다. Apply
전용 로컬 작업 공간은 git에서 제외한 `tofu-apply.auto.tfvars`로 account-local `tofu-apply` role을
지정한다. Backend의 기본 `assume_role`은 `tofu-state-readonly`다. Apply 전용 로컬 작업 공간은
git에서 제외한 `tofu-state-apply.tfbackend`로 `tofu-state-apply`를 지정한다. Remote state는 항상
`tofu-state-readonly`를 수임한다. State 객체 읽기와 쓰기는 backend role만 담당한다. Plan과
Apply는 각각 대응하는 source profile 하나만 사용한다.

공용 state role 두 개의 trust는 Organization `o-ncl6mypc8p` 소속이고 이름이 matching
`TofuPlanFor*` 또는 `TofuApplyFor*`인 IAM Identity Center role과 SharedServices `deployer`만
허용한다. Account wildcard는 앞으로 추가할 workload account의 같은 permission set을 포함한다.
사용자 role과 다른 Organization의 role은 수임할 수 없다.

`tofu-state-admin`은 SharedServices의 `TofuApplyForWorkloads` source identity와 `deployer`만
수임한다. Active bucket `ghilbut-tfstates`의 설정과 자신의 IAM role 설명, session duration, tag,
inline policy를 관리한다. State object API의 직접 IAM 권한은 없지만 bucket policy를 관리하므로
다른 principal의 object 접근 위임은 변경할 수 있다. `s3:DeleteBucket`은 명시적으로 거부한다.
이 역할과 state bucket은 전용 state root가 구성될 때까지 `aws/shared-services/tofu/`에서 관리한다.

`aws_execution_role_arn = null`은 execution role이 아직 없는 새 account bootstrap에서만 source
identity를 provider에 직접 연결한다. 기존 account에서는 `null`을 사용하지 않는다.

Domains `tofu-apply`는 자신의 trust policy만 갱신한다. 이 권한은 permission set과 `deployer`
trust를 OpenTofu로 유지하기 위해 필요하며 다른 IAM role에는 적용되지 않는다.

Permission set session duration과 account-local role의 configured maximum session duration은
4시간이다. SSO role이 account-local role을 수임하면 IAM role chaining에 따라 execution role
session은 최대 1시간이다.

`aws/shared-services/tofu/`의 기본 provider와 `aws.shared_services` provider alias는 모두
`aws_execution_role_arn`을 수임한다. UltaryDomains만 `AWS_PROFILE` source identity를 provider에서
직접 사용한다.

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
관리한다. Lambda bundle은 git에서 관리하므로 clone 직후에도 Plan이 성공한다.

CDN 배포 workflow는 AWS profile을 사용하지 않는다. 현재 GitHub OIDC가 SharedServices
`deployer`를 사용한다. Backend는 `tofu-state-apply`를 수임하고 provider는 `tofu-apply`를
수임한다. 같은 `deployer`가 향후 OpenTofu Plan·Apply와 CDN 배포를 포함한 CI/CD를 담당한다.
Tekton은 `deployer` trust에 인증 방식을 추가하여 같은 역할을 사용한다. 개발자의 기본 backend와
provider는 각각 `tofu-state-readonly`와 `tofu-plan`을 수임한다.

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
