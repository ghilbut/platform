---
title: AWS account split inventory
---

# AWS account split inventory

## Account responsibilities

| Account | ID | Responsibility |
|---|---|---|
| Management | `384959722788` | AWS Organizations와 IAM Identity Center |
| Domains | `869061964712` | Domain registration, Route 53와 DNS federation |
| Platform | `012646747332` | Workload, shared state와 CI federation |
| UltaryDomains | `971119963968` | Ultary domain registration과 Route 53 |

각 resource는 하나의 OpenTofu state만 관리한다.

## Active state

| State key | Root | Owner |
|---|---|---|
| `platform/aws/foundation/accounts.tfstate` | `aws/foundation/accounts/tofu/` | Management |
| `platform/aws/foundation/identity.tfstate` | `aws/foundation/identity/tofu/` | Management |
| `platform/aws/foundation/state.tfstate` | `aws/foundation/state/tofu/` | Platform |
| `platform/aws/foundation/workload.tfstate` | `aws/foundation/workload/tofu/` | Platform |
| `platform/aws/cdn.tfstate` | `aws/cdn/tofu/` | Platform |
| `platform/domains.tfstate` | `domains/tofu/` | Domains |
| `platform/apps.tfstate` | `apps/tofu/` | Platform |
| `platform/github.tfstate` | `github/tofu/` | Platform |
| `k3s.tfstate` | `k3s/tofu/` | Platform |
| `ultary/domains.tfstate` | `ultary/domains/tofu/` | UltaryDomains |

모든 active state는 Platform의 `ghilbut-tfstates` bucket에 있다.

## Domains user-managed resources

| Resource | Identifier | Purpose |
|---|---|---|
| Route 53 Domains | `ghilbut.com`, `ghilbut.net` | Registered domain |
| Route 53 hosted zone | `Z193YX3H31OEZV`, `Z3951CLN9YN7OQ` | DNS record |
| IAM Identity Center role | `AWSReservedSSO_TofuApplyForDomains_*` | Domains source identity |
| OpenTofu role | `tofu-apply` | Domains DNS apply |
| CPA IAM OIDC provider | `oidc.k3s.ghilbut.com/cpa` | DNS workload federation |
| cert-manager role | `domains-cpa-cert-manager` | Route 53 DNS-01 TXT record |
| external-dns role | `domains-cpa-external-dns` | `id.ghilbut.com` CNAME과 TXT record |

Domains account의 live budget 수는 0이다. Customer-managed S3 bucket, Cognito pool과 local IAM
policy는 없다.

## Scheduled KMS key deletion

Customer-managed KMS key `6ebc75ad-c084-4c1a-842e-b45482e5e668`은 Domains 유지
resource가 아니다. AWS KMS가 반환한 상태는 `PendingDeletion`이고 예약 삭제 시각은
`2026-09-04T01:16:50.578+09:00`이다. 실제 삭제 시각은 예약 삭제 시각보다 최대 24시간
늦을 수 있다. AWS KMS가 삭제를 완료하므로 추가 삭제 작업은 없다.

## Absent user-managed resources

직접 service API에서 다음 resource는 없다.

- IAM `tofu-apply`, `cashflow-SMS-Role`, `platform-cdn-github-actions`
- IAM policy `service-role/Cognito-1480509629079`
- IAM Identity Center `TofuApplyForWorkloads` Domains assignment
- IAM virtual MFA `Authapp`
- GitHub Actions IAM OIDC provider in Domains
- ECS `finpc-*` task definition
- CloudWatch alarm `Budgets_Actual_1467215008539`
- SNS topic `aws_budget_da141ba7-4c82-4095-8f6e-e7a9d0d8c63f`
- Resource Explorer view와 index
- Legacy CDN distribution, certificate, Lambda@Edge, bucket, role과 regional log group

## AWS-managed account baseline

다음 resource는 AWS가 만들고 관리한다.

- `alias/aws/acm`, `alias/aws/lambda` KMS key
- Organizations, IAM Identity Center, Support, Trusted Advisor와 Service Quotas service-linked role
- Lambda replicator와 CloudFront logger service-linked role
- Athena primary workgroup과 catalog
- EventBridge default bus와 X-Ray default sampling rule
- RDS, ElastiCache, MemoryDB와 App Runner default resource
- S3 Storage Lens default dashboard

## Credential paths

| Profile | Account | Permission set |
|---|---|---|
| `ghilbut-tofu-apply-for-management` | Management | `TofuApplyForManagement` |
| `ghilbut-tofu-apply-for-domains` | Domains | `TofuApplyForDomains` |
| `ghilbut-tofu-apply-for-workloads` | Platform | `TofuApplyForWorkloads` |
| `ghilbut-tofu-apply-for-ultary-domains` | UltaryDomains | `TofuApplyForUltaryDomains` |

Repository의 provider, backend와 Runbook은 이 네 profile만 사용한다.

## External dependencies

| Consumer | Resource |
|---|---|
| cert-manager on CPA | `domains-cpa-cert-manager` |
| external-dns on CPA | `domains-cpa-external-dns` |
| CDN OpenTofu | Domains state의 ACM validation CNAME과 CloudFront alias |
| K3s ServiceAccount federation | Platform CDN의 discovery document와 JWKS |
| GitHub Actions | Platform `cdn-platform-github-actions` role |
| Google Workspace | Domains hosted zone의 MX, DKIM TXT와 service CNAME |

## Verification

IAM, KMS, S3, Budgets, CloudWatch, SNS, ECS, Cognito와 Resource Explorer의 직접 API 결과를
확인한다. Direct API 결과를 service index의 지연된 record보다 우선한다.
