---
title: AWS account split migration inventory
type: reference
area: aws-foundation
tags:
  - aws
  - migration
  - inventory
---

# AWS account split migration inventory

이 문서는 parent [Issue #65](https://github.com/ghilbut/platform/issues/65)의 AWS 리소스,
OpenTofu state, GitHub 설정, 외부 의존성을 분류한다. 검증 기준일은 2026-08-04다.

## Account ownership

| Account | ID | Root email | 책임 |
|---|---:|---|---|
| Management | `384959722788` | `aws@ghilbut.com` | AWS Organizations, IAM Identity Center, Foundation |
| Domains | `869061964712` | `aws-domains@ghilbut.com` | `ghilbut.com`, `ghilbut.net` 등록과 Route 53 |
| Platform | `012646747332` | `aws-platform@ghilbut.com` | state backend, CDN, Vault, workload IAM |
| UltaryDomains | `971119963968` | `aws-ultary-domains@ghilbut.com` | Ultary 도메인 등록과 Route 53 |

AWS Organizations 이름은 `869061964712`가 `domains`, `012646747332`가 `platform`,
`971119963968`이 `UltaryDomains`다. `aws/foundation/accounts/tofu/`의 root email은 live 값과
일치한다.

## Disposition rules

| 분류 | 처리 |
|---|---|
| Domains retained | 도메인 등록, hosted zone, record, Route 53 변경용 IAM federation을 `869061964712`에 유지한다. |
| Platform recreated | Account ID가 포함된 리소스를 새 Platform account에서 새로 만들고 사용자를 전환한 뒤 기존 리소스를 삭제한다. |
| Backend migrated | `tofu init -migrate-state`만 사용해 새 Platform state bucket으로 이전한다. state object와 lock file을 직접 복사하지 않는다. |
| Removed | 사용하지 않는 사용자 관리 리소스는 표에 지정한 follow-up Issue에서 삭제한다. |
| AWS managed | AWS가 만드는 service-linked role, default resource, AWS managed KMS key는 이동하지 않는다. 연결된 사용자 관리 workload를 삭제한 뒤 AWS가 허용하는 항목만 정리한다. |

## OpenTofu state inventory

`ghilbut-tfstates`에는 다음 state object가 있다. 모든 활성 backend는
[Issue #97](https://github.com/ghilbut/platform/issues/97)에서 새 Platform account로 이전한다.

| State key | Active root | Resource owner | Disposition |
|---|---|---|---|
| `k3s.tfstate` | `k3s/tofu/` | Domains와 Platform | Backend는 [Issue #97](https://github.com/ghilbut/platform/issues/97)에서 이전한다. CPA OIDC provider는 [Issue #102](https://github.com/ghilbut/platform/issues/102)에서 두 account의 책임으로 분리하고 CDN object는 [Issue #98](https://github.com/ghilbut/platform/issues/98)에서 이전한다. |
| `platform/apps.tfstate` | `apps/tofu/` | Domains와 Platform | Backend는 [Issue #97](https://github.com/ghilbut/platform/issues/97)에서 이전한다. Route 53 역할은 Domains에 유지하고 Vault 리소스는 [Issue #102](https://github.com/ghilbut/platform/issues/102)에서 Platform에 재생성한다. |
| `platform/aws/accounts.tfstate` | 없음 | Management | 비활성 state다. `platform/aws/foundation/accounts.tfstate`와 resource address를 대조한 뒤 [Issue #97](https://github.com/ghilbut/platform/issues/97)에서 삭제한다. |
| `platform/aws/cdn.tfstate` | `aws/cdn/tofu/` | Domains와 Platform | Backend는 [Issue #97](https://github.com/ghilbut/platform/issues/97)에서 이전한다. Route 53 record 소유권은 [Issue #103](https://github.com/ghilbut/platform/issues/103)에서 Domains state로 옮긴다. `tofu-apply` 역할은 [Issue #96](https://github.com/ghilbut/platform/issues/96)과 [Issue #99](https://github.com/ghilbut/platform/issues/99)에서 분리하고 나머지 CDN 리소스는 [Issue #98](https://github.com/ghilbut/platform/issues/98)에서 Platform에 재생성한다. |
| `platform/aws/foundation/accounts.tfstate` | `aws/foundation/accounts/tofu/` | Management | Backend만 [Issue #97](https://github.com/ghilbut/platform/issues/97)에서 이전한다. |
| `platform/aws/foundation/identity.tfstate` | `aws/foundation/identity/tofu/` | Management | Backend만 [Issue #97](https://github.com/ghilbut/platform/issues/97)에서 이전한다. Account assignment는 [Issue #96](https://github.com/ghilbut/platform/issues/96)과 [Issue #99](https://github.com/ghilbut/platform/issues/99)에서 변경한다. |
| `platform/aws/foundation/state.tfstate` | `aws/foundation/state/tofu/` | Platform | [Issue #97](https://github.com/ghilbut/platform/issues/97)에서 새 bucket policy state로 교체한다. |
| `platform/aws/foundation/workload.tfstate` | `aws/foundation/workload/tofu/` | Platform | Backend만 [Issue #97](https://github.com/ghilbut/platform/issues/97)에서 이전한다. Platform 실행 역할은 [Issue #96](https://github.com/ghilbut/platform/issues/96)에서 생성했다. |
| `platform/domains.tfstate` | `domains/tofu/` | Domains | Backend만 [Issue #97](https://github.com/ghilbut/platform/issues/97)에서 이전한다. 도메인과 hosted zone은 Domains에 유지한다. |
| `platform/github.tfstate` | `github/tofu/` | Platform | Backend는 [Issue #97](https://github.com/ghilbut/platform/issues/97)에서 이전하고 GitHub Actions OIDC provider는 [Issue #98](https://github.com/ghilbut/platform/issues/98)에서 Platform에 재생성한다. |
| `ultary/domains.tfstate` | `ultary/domains/tofu/` | UltaryDomains | Backend만 [Issue #97](https://github.com/ghilbut/platform/issues/97)에서 이전한다. |

## AWS resource inventory

### Domains retained

| Resource | Identifier | Owner after split | Reason |
|---|---|---|---|
| Route 53 Domains | `ghilbut.com`, `ghilbut.net` | Domains | Registered domain은 Domains 책임이다. |
| Route 53 hosted zone | `Z193YX3H31OEZV` (`ghilbut.com`) | Domains | DNS record와 ACM validation record를 유지한다. |
| Route 53 hosted zone | `Z3951CLN9YN7OQ` (`ghilbut.net`) | Domains | DNS record를 유지한다. |
| IAM Identity Center role | `AWSReservedSSO_TofuApplyForDomains_*` | Domains | Domains의 source identity다. 실행 역할은 아직 없으며 [Issue #103](https://github.com/ghilbut/platform/issues/103)에서 전용 `tofu-apply` 역할을 만든다. |
| CPA IAM OIDC provider | `oidc.k3s.ghilbut.com/cpa` | Domains | cert-manager와 external-dns의 Route 53 역할이 사용한다. [Issue #102](https://github.com/ghilbut/platform/issues/102)에서 Platform에도 별도로 등록한다. |
| cert-manager IAM role | `platform-cpa-cert-manager` | Domains | Route 53 DNS-01 전용 역할이다. [Issue #102](https://github.com/ghilbut/platform/issues/102)에서 최종 이름과 manifest ARN을 갱신한다. |
| external-dns IAM role | `platform-cpa-external-dns` | Domains | Route 53 record 전용 역할이다. [Issue #102](https://github.com/ghilbut/platform/issues/102)에서 최종 이름과 manifest ARN을 갱신한다. |
| Account billing baseline | payment instrument | Domains | AWS account 자체의 결제 수단이다. 다른 account로 이동하지 않는다. |

### Platform recreated

| Resource group | Current identifiers | Follow-up |
|---|---|---|
| OpenTofu backend | S3 `ghilbut-tfstates`, bucket policy, 10 state objects | [Issue #97](https://github.com/ghilbut/platform/issues/97)은 `ghilbut-tfstates-v2`를 만들고 모든 활성 backend, state bucket IAM policy ARN, CDN CI policy, CDN remote-state 참조를 이전한다. |
| Workload execution | IAM `tofu-apply`, `TofuApplyForWorkloads` assignment | 현재 역할은 CDN state가 소유한다. [Issue #96](https://github.com/ghilbut/platform/issues/96)은 별도 bootstrap 구성으로 새 Platform 역할과 임시 이중 assignment를 만들고 [Issue #99](https://github.com/ghilbut/platform/issues/99)는 Domains의 기존 역할과 assignment를 삭제한다. |
| Vault seal | KMS alias `alias/platform-vault`, customer key `6ebc75ad-c084-4c1a-842e-b45482e5e668`, IAM `platform-vault` | [Issue #102](https://github.com/ghilbut/platform/issues/102)는 새 key와 역할을 만든 뒤 Vault seal migration을 실행한다. KMS key와 ciphertext는 account 사이에서 이동하지 않는다. |
| Shared GitHub federation | IAM OIDC provider `token.actions.githubusercontent.com` | [Issue #98](https://github.com/ghilbut/platform/issues/98)은 새 Platform account에서 재생성한다. |
| CDN origin | S3 `ghilbut-platform-cdn`과 5개 object | [Issue #98](https://github.com/ghilbut/platform/issues/98)은 공존 기간의 전역 이름 충돌을 피하려고 의도적으로 `ghilbut-cdn-platform`을 사용하고 정적 파일과 OIDC 문서를 전환한다. |
| CDN delivery | CloudFront distribution `E1FNHJ17EQ6KS9`, OAC `EX9WZIAWVVILI`, function `platform-cdn-viewer-request` | [Issue #98](https://github.com/ghilbut/platform/issues/98)은 새 distribution을 검증한 뒤 Domains state의 alias를 새 endpoint로 전환하고 기존 distribution을 삭제한다. |
| CDN edge compute | Lambda `platform-cdn-origin-request`, IAM `platform-cdn-lambda`, 7개 리전의 CloudWatch log group | [Issue #98](https://github.com/ghilbut/platform/issues/98)은 새 account에 재생성하고 Lambda@Edge replica 제거를 확인한 뒤 기존 리소스를 삭제한다. |
| CDN certificate | ACM certificate `267cc7ba-5b74-40fe-9a93-bd49300755aa` | [Issue #98](https://github.com/ghilbut/platform/issues/98)은 Platform에서 certificate를 요청한다. Domains state가 validation record를 만든 뒤 Platform이 validation을 완료한다. |
| CDN deployment | IAM `platform-cdn-github-actions` | [Issue #98](https://github.com/ghilbut/platform/issues/98)은 새 role을 만든 뒤 GitHub repository variable을 갱신한다. |

### Removed or reconciled

| Resource | Current state | Disposition |
|---|---|---|
| IAM `cashflow-SMS-Role` | Cognito trust, last-used 정보 없음 | Cognito user pool과 identity pool이 없다. [Issue #99](https://github.com/ghilbut/platform/issues/99)에서 role과 `Cognito-1480509629079` policy를 삭제한다. |
| Virtual MFA `Authapp` | IAM user 연결 없음 | [Issue #99](https://github.com/ghilbut/platform/issues/99)에서 미할당 상태를 다시 확인하고 삭제한다. |
| Resource Explorer index and view | `us-east-1` local index | [Issue #99](https://github.com/ghilbut/platform/issues/99) 최종 인벤토리 후 삭제한다. |
| ECS task definition | `finpc-nginx:1`, `finpc-nextjs:1-3` in `ap-northeast-2` | `finpc-nextjs:2-3`은 active이고 나머지 두 revision은 inactive다. 실행 중 ECS cluster, ECR repository, IAM execution role이 없다. [Issue #99](https://github.com/ghilbut/platform/issues/99)에서 active revision을 deregister하고 네 revision을 삭제한다. |
| Budget notification resources | CloudWatch alarm `Budgets_Actual_1467215008539`, SNS topic `aws_budget_da141ba7-4c82-4095-8f6e-e7a9d0d8c63f` | [Issue #99](https://github.com/ghilbut/platform/issues/99)에서 account budget 연결을 확인하고 사용하지 않으면 삭제한다. |
| IAM Identity Center workload role | `AWSReservedSSO_TofuApplyForWorkloads_*` | [Issue #99](https://github.com/ghilbut/platform/issues/99)에서 Domains assignment를 제거하면 IAM Identity Center가 삭제한다. |
| Local AWS profile | `ghilbut-platform` → account `869061964712`, removed permission set `TofuApply` | 현재 provider와 backend 참조는 새 SSO profile과 실행 역할 경로로 교체한다. Domains는 [Issue #103](https://github.com/ghilbut/platform/issues/103), apps와 K3s는 [Issue #102](https://github.com/ghilbut/platform/issues/102), GitHub는 [Issue #98](https://github.com/ghilbut/platform/issues/98), backend는 [Issue #97](https://github.com/ghilbut/platform/issues/97)에서 처리한다. |
| CDN log group and service-linked roles | `eu-central-1`, `eu-west-1`, `eu-west-2`, `us-east-1`, `us-east-2`, `us-west-1`, `us-west-2`의 Lambda@Edge log group과 CloudFront 관련 role | [Issue #98](https://github.com/ghilbut/platform/issues/98)에서 CDN 삭제와 replica 정리를 끝낸 뒤 사용하지 않는 항목을 삭제한다. |
| AWS Organizations account configuration | `aws/foundation/accounts/tofu/main.tf`의 `869061964712` root email이 `aws-platform@ghilbut.com`으로 남아 있다. | [Issue #96](https://github.com/ghilbut/platform/issues/96)에서 다음 accounts plan 전에 live 값 `aws-domains@ghilbut.com`으로 맞추고 account 이름과 resource address를 정리한다. |

### AWS-managed account baseline

다음 항목은 workload migration 대상이 아니다.

- `alias/aws/acm`, `alias/aws/lambda` AWS managed KMS key
- Organizations, SSO, Support, Trusted Advisor, Service Quotas service-linked role
- Lambda replicator와 CloudFront logger service-linked role
- Athena primary workgroup과 catalog, EventBridge default bus, X-Ray default sampling rule
- RDS, ElastiCache, MemoryDB, App Runner의 default resource
- S3 Storage Lens default dashboard

AWS Resource Explorer 결과보다 각 service의 live API 결과를 우선한다. Resource Explorer에는
삭제된 IAM Identity Center role이 일정 시간 남을 수 있다.

17개 기본 활성 리전의 Tagging, EC2, Lambda, RDS, DynamoDB, ECS, EKS, ECR, SNS, SQS,
Cognito, CloudFormation, CloudWatch, SSM, ACM, Secrets Manager, KMS API를 확인했다.
`us-east-1`의 위 리소스, 7개 리전의 Lambda@Edge log group, `ap-northeast-2`의 고아 ECS
task definition 네 revision 외에 사용자 관리 workload는 없다. IAM user와 group도 없다.
Tagging API가 반환한 종료된 SSM session은 활성 리소스가 아니다.

## Credential path inventory

| Profile or permission set | Current state | Disposition |
|---|---|---|
| `ghilbut-platform` | Account `869061964712`의 삭제된 `TofuApply` permission set을 가리킨다. 새 role credential을 발급할 수 없다. | 모든 provider와 backend에서 제거한다. |
| `ghilbut-tofu-apply-for-workloads` | Account `869061964712`의 `TofuApplyForWorkloads`를 사용한다. | [Issue #96](https://github.com/ghilbut/platform/issues/96)에서 기존 설정은 임시 `ghilbut-tofu-apply-for-workloads-domains`로 이름을 바꾸고 원래 profile 이름은 새 Platform account에 연결한다. [Issue #99](https://github.com/ghilbut/platform/issues/99)에서 임시 profile과 Domains 할당을 제거한다. |
| `ghilbut-tofu-apply-for-domains` | Repository 문서에 구성 절차가 있지만 local AWS config에는 없다. | [Issue #103](https://github.com/ghilbut/platform/issues/103)에서 구성하고 Domains `tofu-apply` 역할을 수임한다. |
| `TofuApplyForDomains` | Domains account에 할당되어 있고 `AmazonRoute53FullAccess`가 연결되어 있다. | [Issue #103](https://github.com/ghilbut/platform/issues/103)에서 source identity로만 사용하고 실행 역할 수임 권한과 state 접근만 추가한다. |

## GitHub inventory

| Item | Value | Disposition |
|---|---|---|
| Repository variable | `AWS_IAM_ROLE_CDN_GITHUB_ACTIONS_ARN=arn:aws:iam::869061964712:role/platform-cdn-github-actions` | [Issue #98](https://github.com/ghilbut/platform/issues/98)에서 새 Platform role ARN으로 갱신한다. |
| Workflow | `.github/workflows/aws-cdn-lambda.yml` | Variable 갱신 후 새 Platform role로 배포를 검증한다. |
| Repository secret reference | 없음 | Repository workflow와 OpenTofu 구성은 `secrets.*`와 `github_actions_secret`을 사용하지 않는다. |

GitHub token에는 Actions secret metadata 읽기 권한이 없다. 저장소 구성은 secret을 참조하지
않으며 CDN 배포는 OIDC와 repository variable만 사용한다.

## External dependencies

| Consumer | Dependency | Required change |
|---|---|---|
| OpenTofu state consumers | `aws/foundation/identity/tofu/main.tf`의 policy ARN, `aws/cdn/tofu/main.tf`의 CI policy, `aws/cdn/tofu/github.tf`의 remote state | [Issue #97](https://github.com/ghilbut/platform/issues/97)에서 backend와 함께 `ghilbut-tfstates-v2`로 변경한다. |
| Vault on CPA | `platform-vault` role과 KMS seal key | [Issue #102](https://github.com/ghilbut/platform/issues/102)에서 recovery-key holder가 seal migration을 실행하고 새 ARN을 `apps/argo-apps/vault.yaml`에 반영한다. |
| cert-manager on CPA | `platform-cpa-cert-manager` role | [Issue #102](https://github.com/ghilbut/platform/issues/102)에서 Domains의 최종 role ARN을 `apps/argo-apps/cert-manager/issuer.yaml`에 반영한다. |
| external-dns on CPA | `platform-cpa-external-dns` role | [Issue #102](https://github.com/ghilbut/platform/issues/102)에서 Domains의 최종 role ARN을 `apps/argo-apps/external-dns.yaml`에 반영한다. |
| CDN OpenTofu | Domains hosted zone의 ACM validation record와 CDN alias | [Issue #103](https://github.com/ghilbut/platform/issues/103)에서 두 record 종류를 Domains state로 옮긴다. [Issue #98](https://github.com/ghilbut/platform/issues/98)은 certificate 요청, validation record 적용, CDN 생성, alias 전환 순서로 실행한다. |
| K3s ServiceAccount federation | `https://oidc.k3s.ghilbut.com/cpa` discovery 문서와 JWKS | [Issue #98](https://github.com/ghilbut/platform/issues/98) CDN 전환 중에도 issuer URL과 문서 내용을 유지한다. |
| GitHub Actions | repository variable의 IAM role ARN | [Issue #98](https://github.com/ghilbut/platform/issues/98)에서 variable 갱신과 OIDC 배포를 같은 전환으로 검증한다. |
| IAM Identity Center local profiles | account ID와 permission set assignment | [Issue #96](https://github.com/ghilbut/platform/issues/96)에서 새 Platform account ID를 추가하고 [Issue #99](https://github.com/ghilbut/platform/issues/99)에서 Domains workload profile을 제거한다. |
| Google Workspace | Domains hosted zone의 MX, DKIM TXT, service URL CNAME | `domains/tofu/`에서 유지한다. |

## Resources that cannot move between accounts

- AWS Organizations member account ID와 root email은 다른 account로 이동하지 않는다.
- S3 bucket ownership은 이동하지 않는다. [Issue #97](https://github.com/ghilbut/platform/issues/97)과 [Issue #98](https://github.com/ghilbut/platform/issues/98)은 새 bucket을 만들고 지원되는 migration 또는 application upload를 사용한다.
- KMS key와 ciphertext는 이동하지 않는다. Vault는 [Issue #102](https://github.com/ghilbut/platform/issues/102)에서 seal migration을 실행한다.
- IAM role, policy, OIDC provider ARN은 account ID를 포함한다. 대상 account에서 재생성한다.
- ACM certificate, Lambda, CloudFront distribution, function, OAC는 대상 account에서 재생성한다.
- IAM Identity Center account assignment는 대상 account ID로 새로 만든다.
- GitHub repository variable은 새 IAM role ARN으로 갱신한다.

## Follow-up order

Parent [Issue #65](https://github.com/ghilbut/platform/issues/65)의 sub-issue와 blocking
관계가 다음 순서를 강제한다.

1. [Issue #100](https://github.com/ghilbut/platform/issues/100) — Domains root email 변경 완료
2. [Issue #95](https://github.com/ghilbut/platform/issues/95) — 이 인벤토리 확정
3. [Issue #96](https://github.com/ghilbut/platform/issues/96) — 새 Platform account와 workload access 생성
4. [Issue #97](https://github.com/ghilbut/platform/issues/97) — state backend 이전
5. [Issue #103](https://github.com/ghilbut/platform/issues/103) — Domains 실행 역할과 CDN DNS state 소유권 확정
6. [Issue #102](https://github.com/ghilbut/platform/issues/102) — Vault와 application IAM federation 이전
7. [Issue #98](https://github.com/ghilbut/platform/issues/98) — CDN 전환
8. [Issue #99](https://github.com/ghilbut/platform/issues/99) — Domains cleanup과 workload access 정리
