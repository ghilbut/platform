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
| [cdn/](cdn/README.md) | SharedServices 계정의 CloudFront CDN과 배포 코드 |
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
| `foundation/identity/tofu/` | IAM Identity Center permission set, DevOps·Developers group, account assignment와 Management execution role |
| `foundation/identity/tofu/modules/permission-set/` | permission set, 정책 연결과 account assignment 조합 |
| `foundation/organizations/tofu/` | AWS Organization, OU, SCP와 delegated administrator |
| `security-tooling/tofu/` | SecurityTooling 계정의 OpenTofu Plan과 Apply execution role |
| `shared-services/state/tofu/` | `ghilbut-tfstates`의 bucket 설정과 `tofu-state-admin` |
| `shared-services/tofu/` | 중앙 state backend role, `deployer`, SharedServices workload execution role, GitHub Actions, CPA IAM OIDC provider와 platform backup 저장소 |

Foundation에는 accounts, identity와 organizations 책임만 둔다. `organizations/tofu/`는 AWS
Organization, Infrastructure OU, Security OU, SCP와 trusted access를 관리한다.

## State ownership

모든 active state는 SharedServices 계정의 versioned S3 bucket `ghilbut-tfstates`에 저장하고 같은
이름의 `.tflock` object를 사용한다. 하나의 resource는 하나의 state만 관리한다.

모든 backend의 기본 역할은 SharedServices `tofu-state-readonly`다. 이 역할은 active `.tfstate`를
읽고 대응하는 `.tflock`을 읽고 쓰고 삭제한다. Apply backend는 로컬 `.tfbackend` 설정으로
SharedServices `tofu-state-apply`를 수임한다. 이 역할은 active `.tfstate`와 `.tflock`을 읽고 쓰고
삭제한다. 두 역할은 recovery state와 `ghilbut-tfstates-v2`에 접근하지 않는다.

State bucket 6개 리소스와 `tofu-state-admin`은 `aws/shared-services/state/tofu/`의
`platform/aws/shared-services/state.tfstate`가 소유한다. 중앙 state role은 이 key와 대응하는
lock key에 접근한다.

| Root | State key | Account | Plan source profile | Apply source profile |
|---|---|---|---|---|
| `aws/foundation/accounts/tofu/` | `platform/aws/foundation/accounts.tfstate` | Management | `ghilbut-tofu-plan-for-management` | `ghilbut-tofu-apply-for-management` |
| `aws/foundation/identity/tofu/` | `platform/aws/foundation/identity.tfstate` | Management | `ghilbut-tofu-plan-for-management` | `ghilbut-tofu-apply-for-management` |
| `aws/foundation/organizations/tofu/` | `platform/aws/foundation/organizations.tfstate` | Management | `ghilbut-tofu-plan-for-management` | `ghilbut-tofu-apply-for-management` |
| `aws/shared-services/tofu/` | `platform/aws/shared-services.tfstate` | SharedServices | `ghilbut-tofu-plan-for-workloads` | `ghilbut-tofu-apply-for-workloads` |
| `aws/shared-services/state/tofu/` | `platform/aws/shared-services/state.tfstate` | SharedServices | `ghilbut-tofu-plan-for-workloads` | `ghilbut-tofu-apply-for-workloads` |
| `aws/security-tooling/tofu/` | `platform/aws/security-tooling.tfstate` | SecurityTooling | `ghilbut-tofu-plan-for-security-tooling` | `ghilbut-tofu-apply-for-security-tooling` |
| `aws/cdn/tofu/` | `platform/aws/cdn.tfstate` | SharedServices | `ghilbut-tofu-plan-for-workloads` | `ghilbut-tofu-apply-for-workloads` |
| `apps/tofu/` | `platform/apps.tfstate` | SharedServices | `ghilbut-tofu-plan-for-workloads` | `ghilbut-tofu-apply-for-workloads` |
| `k3s/tofu/` | `k3s.tfstate` | SharedServices | `ghilbut-tofu-plan-for-workloads` | `ghilbut-tofu-apply-for-workloads` |
| `domains/tofu/` | `platform/domains.tfstate` | Domains | `ghilbut-tofu-plan-for-domains` | `ghilbut-tofu-apply-for-domains` |
| `ultary/domains/tofu/` | `ultary/domains.tfstate` | UltaryDomains | `ghilbut-tofu-plan-for-ultary-domains` | `ghilbut-tofu-apply-for-ultary-domains` |

## Management access

Management console 책임과 Billing 책임은 서로 다른 permission set으로 관리한다.

| Permission set | Assignment | Profile | IAM Identity Center role | 책임 |
|---|---|---|---|---|
| `FoundationManagement` | Management `384959722788` | `ghilbut-foundation-management` | `AWSReservedSSO_FoundationManagement_*` | AWS Organizations, account와 IAM Identity Center 관리 |
| `Billing` | Management `384959722788` | `ghilbut-billing` | `AWSReservedSSO_Billing_*` | Billing과 비용 관리 |

Management root user는 Billing account 설정에서 `Activate IAM access`를 한 번 활성화한다. 이
account 설정과 `Billing` permission set이 모두 적용되어야 IAM Identity Center 사용자가 Billing
Console을 열 수 있다.

## Developer access

`Developers` Permission Set은 workload와 Domains account에 직접 읽기 권한을 제공한다. AWS 관리형
`ViewOnlyAccess`와 `CloudWatchReadOnlyAccess`에 민감정보 거부 정책과 필요한 추가 조회 권한을
결합한다.

| Permission set | Assignment | Profile | IAM Identity Center role |
|---|---|---|---|
| `Developers` | SharedServices `012646747332` | `ghilbut-developers-for-shared-services` | `AWSReservedSSO_Developers_*` |
| `Developers` | SecurityTooling `954066442429` | `ghilbut-developers-for-security-tooling` | `AWSReservedSSO_Developers_*` |
| `Developers` | Domains `869061964712` | `ghilbut-developers-for-domains` | `AWSReservedSSO_Developers_*` |

`Developers`의 정보 분류와 접근 범위는
[[knowledge/rulebooks/aws/DEVELOPER-ACCESS|AWS 개발자 접근 기준]]을 따른다.

## OpenTofu access

`TofuPlanFor*`와 `TofuApplyFor*`는 IAM Identity Center source identity다. 하나의 source
profile을 backend와 provider가 함께 사용한다. Backend는 SharedServices의 중앙 state role을
수임하고 provider는 대상 account의 `tofu-plan` 또는 `tofu-apply` execution role을 수임한다.

| Permission set | Assignment | Source profile | Account-local role | Role owner | 사용하는 root |
|---|---|---|---|---|---|
| `TofuPlanForManagement` | Management `384959722788` | `ghilbut-tofu-plan-for-management` | `arn:aws:iam::384959722788:role/tofu-plan` | `aws/foundation/identity/tofu/` | Foundation accounts, identity, organizations |
| `TofuApplyForManagement` | Management `384959722788` | `ghilbut-tofu-apply-for-management` | `arn:aws:iam::384959722788:role/tofu-apply` | `aws/foundation/identity/tofu/` | Foundation accounts, identity, organizations |
| `TofuPlanForWorkloads` | SharedServices `012646747332` | `ghilbut-tofu-plan-for-workloads` | `arn:aws:iam::012646747332:role/tofu-plan` | `aws/shared-services/tofu/` | SharedServices, state, CDN, apps, GitHub, K3s |
| `TofuApplyForWorkloads` | SharedServices `012646747332` | `ghilbut-tofu-apply-for-workloads` | `arn:aws:iam::012646747332:role/tofu-apply` 또는 `arn:aws:iam::012646747332:role/tofu-state-admin` | `aws/shared-services/tofu/`, `aws/shared-services/state/tofu/` | SharedServices, state, CDN, apps, GitHub, K3s |
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
`tofu-apply`는 `PowerUserAccess`, `IAMFullAccess`와 중앙 관리·state 관리 거부 정책을 사용한다.
모든 workload account에 같은 정책을 적용하며 account별 resource 정책을 추가하지 않는다.
`tofu-plan`은 `ghilbut-tfstates`와 `ghilbut-tfstates-v2`의 객체에 직접 접근하지 못한다.
`tofu-apply`는 두 bucket의 bucket API와 object API를 직접 사용할 수 없고 `tofu-state-admin`을
수임하거나 변경할 수 없다.

SharedServices `deployer`는 Management, SharedServices, SecurityTooling과 Domains의
`tofu-plan`·`tofu-apply`, `tofu-state-admin` 및 공용 state role을 수임한다. GitHub Actions는
OIDC로 이 role에 로그인한다. UltaryDomains는 별도 운영 계정이므로 포함하지 않는다.
단일 source role의 범위는 각 target role 정책과 GitHub main branch OIDC 조건으로 제한한다.

## OpenTofu Plan automation

GitHub Actions의 `tofu-plan-changed.yml`과 `tofu-plan-all.yml`은 SharedServices `deployer`로
로그인한다. Backend는 기본 `tofu-state-readonly`, provider는 root별 기본 `tofu-plan`을 수임한다.
AWS profile, 정적 AWS access key, Apply provider override와 Apply backend override는 사용하지
않는다.

`tofu-plan-changed.yml`은 `main` push에서 변경된 CI 관리 root만 Plan한다. 삭제한 파일도 변경으로
처리한다. 비교 기준 revision에 접근할 수 없거나 workflow 파일이 변경되면 모든 CI 관리 root를
Plan한다. `tofu-plan-all.yml`의 수동 실행은 다음 아홉 root를 모두 Plan한다.

Plan과 CDN Apply는 S3 backend의 `.tflock`으로 동일한 state의 실행을 직렬화하고 잠금 해제를 최대
30분 기다린다. CDN Apply workflow의 concurrency group은 CDN Apply끼리만 직렬화한다. 서로 다른
state를 사용하는 Plan은 GitHub concurrency group으로 제한하지 않는다.

| 순서 | Root | Provider account |
|---:|---|---|
| 1 | `aws/foundation/organizations/tofu/` | Management |
| 2 | `aws/foundation/accounts/tofu/` | Management |
| 3 | `aws/foundation/identity/tofu/` | Management |
| 4 | `aws/shared-services/tofu/` | SharedServices |
| 5 | `aws/shared-services/state/tofu/` | SharedServices |
| 6 | `aws/security-tooling/tofu/` | SecurityTooling |
| 7 | `aws/cdn/tofu/` | SharedServices |
| 8 | `domains/tofu/` | Domains |
| 9 | `apps/tofu/` | SharedServices |

CI 관리 root 목록과 실행 순서는 두 Plan workflow의 `CI_MANAGED_TOFU_ROOTS`에 명시한다.
`tofu-plan-changed.yml`의 `push.paths`에는 같은 root의 `tofu/**` 경로를 명시한다. Root 내부 파일
변경은 해당 root를 선택한다. 두 Plan workflow 중 하나의 변경은 모든 CI 관리 root를 선택한다.
`aws/cdn/tofu/` 밖의 CDN 변경은 `aws-cdn-lambda.yml`만 처리한다.

`k3s/tofu/`는 `cpa` Kubernetes API와 로컬 `kubectl` context가 필요하므로 GitHub-hosted runner에서
실행하지 않는다. `ultary/domains/tofu/`는 `deployer` 인가 범위 밖이며 필수 입력값을 별도로
관리하므로 실행하지 않는다.

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
수임한다. Active bucket `ghilbut-tfstates`의 설정과 자신의 IAM role trust policy, 설명, session
duration, tag, inline policy를 관리한다. State object API의 직접 IAM 권한은 없지만 bucket policy를
관리하므로 다른 principal의 object 접근 위임은 변경할 수 있다. `s3:DeleteBucket`은 명시적으로
거부한다. 이 역할과 state bucket은 `aws/shared-services/state/tofu/`에서 관리한다.

`aws_execution_role_arn = null`은 execution role이 아직 없는 새 account bootstrap에서만 source
identity를 provider에 직접 연결한다. 기존 account에서는 `null`을 사용하지 않는다.

Domains `tofu-apply`는 자신의 trust policy만 갱신한다. 이 권한은 permission set과 `deployer`
trust를 OpenTofu로 유지하기 위해 필요하며 다른 IAM role에는 적용되지 않는다.

Permission set session duration과 account-local role의 configured maximum session duration은
4시간이다. SSO role이 account-local role을 수임하면 IAM role chaining에 따라 execution role
session은 최대 1시간이다.

## Platform backup

SharedServices의 `ghilbut-backups` bucket은 platform 복구 데이터를 저장한다. CPA K3s etcd
snapshot은 `k3s/cpa/` prefix를 사용한다. Bucket은 public 접근을 차단하고 TLS, 기본 암호화,
versioning과 90일 noncurrent version 보존을 적용한다. K3s가 current snapshot 수를 관리한다.

`k3s-cpa-snapshot` IAM user는 `k3s/cpa/`에서 snapshot을 생성하고 조회하고 정리한다.
`k3s/tofu`는 이 user의 access key를 생성하고 CPA의 K3s S3 configuration Secret에 직접 적용한다.
Access key ID는 AWS resource 식별자로 Plan과 Apply 진행 로그에 표시된다. Secret access key는
`k3s.tfstate`에 민감한 값으로 저장하며 Plan과 Apply 출력에 표시하지 않는다.

`BackupRecovery` Permission Set은 `k3s/cpa/`의 current object와 noncurrent version을 직접 읽고
bucket과 object를 변경하지 않는다. Session duration은 4시간이다.

| Permission set | Assignment | Profile | IAM Identity Center role | 책임 |
|---|---|---|---|---|
| `BackupRecovery` | SharedServices `012646747332` | `ghilbut-backup-recovery` | `AWSReservedSSO_BackupRecovery_*` | platform backup 읽기 |

`aws/shared-services/state/tofu/`의 provider는 Plan에서 `tofu-plan`, Apply에서
`tofu-state-admin`을 수임한다. UltaryDomains만 `AWS_PROFILE` source identity를 provider에서 직접
사용한다.

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

CDN 배포 workflow는 AWS profile을 사용하지 않는다. GitHub Actions는 OIDC로 SharedServices
`deployer`를 사용한다. Backend는 `tofu-state-apply`를 수임하고 provider는 `tofu-apply`를
수임한다. 같은 `deployer`가 OpenTofu Plan과 CDN 배포를 담당한다. 개발자의 기본 backend와
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
