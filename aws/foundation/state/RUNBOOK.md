---
title: OpenTofu state backend
---

# OpenTofu state backend

Platform account `012646747332`의 `ghilbut-tfstates` bucket이 모든 active OpenTofu
state를 저장한다. Bucket은 versioning, AES256 encryption, BucketOwnerEnforced ownership과
public access block을 사용한다.

## State roots

| Root | State key | Source profile |
|---|---|---|
| `aws/foundation/accounts/tofu/` | `platform/aws/foundation/accounts.tfstate` | `ghilbut-tofu-apply-for-management` |
| `aws/foundation/identity/tofu/` | `platform/aws/foundation/identity.tfstate` | `ghilbut-tofu-apply-for-management` |
| `aws/foundation/state/tofu/` | `platform/aws/foundation/state.tfstate` | `ghilbut-tofu-apply-for-workloads` |
| `aws/foundation/workload/tofu/` | `platform/aws/foundation/workload.tfstate` | `ghilbut-tofu-apply-for-workloads` |
| `aws/cdn/tofu/` | `platform/aws/cdn.tfstate` | `ghilbut-tofu-apply-for-workloads` |
| `domains/tofu/` | `platform/domains.tfstate` | `ghilbut-tofu-apply-for-domains` |
| `apps/tofu/` | `platform/apps.tfstate` | `ghilbut-tofu-apply-for-workloads` |
| `github/tofu/` | `platform/github.tfstate` | `ghilbut-tofu-apply-for-workloads` |
| `k3s/tofu/` | `k3s.tfstate` | `ghilbut-tofu-apply-for-workloads` |
| `ultary/domains/tofu/` | `ultary/domains.tfstate` | `ghilbut-tofu-apply-for-ultary-domains` |

각 state는 같은 이름의 `.tflock` object를 사용한다.

## Access

| Principal | Access |
|---|---|
| Management `TofuApplyForManagement` | Foundation accounts와 identity state read/write |
| Domains `TofuApplyForDomains` | Domains state read/write, CDN state read-only |
| Platform `TofuApplyForWorkloads` | Platform workload state read/write |
| UltaryDomains `TofuApplyForUltaryDomains` | UltaryDomains state read/write |

Bucket policy와 permission set policy는 같은 state key만 허용한다.

## Profiles

```sh
aws configure set sso_session ghilbut --profile ghilbut-tofu-apply-for-management
aws configure set sso_account_id 384959722788 --profile ghilbut-tofu-apply-for-management
aws configure set sso_role_name TofuApplyForManagement --profile ghilbut-tofu-apply-for-management
aws configure set region us-east-1 --profile ghilbut-tofu-apply-for-management

aws configure set sso_session ghilbut --profile ghilbut-tofu-apply-for-domains
aws configure set sso_account_id 869061964712 --profile ghilbut-tofu-apply-for-domains
aws configure set sso_role_name TofuApplyForDomains --profile ghilbut-tofu-apply-for-domains
aws configure set region us-east-1 --profile ghilbut-tofu-apply-for-domains

aws configure set sso_session ghilbut --profile ghilbut-tofu-apply-for-workloads
aws configure set sso_account_id 012646747332 --profile ghilbut-tofu-apply-for-workloads
aws configure set sso_role_name TofuApplyForWorkloads --profile ghilbut-tofu-apply-for-workloads
aws configure set region us-east-1 --profile ghilbut-tofu-apply-for-workloads

aws configure set sso_session ghilbut --profile ghilbut-tofu-apply-for-ultary-domains
aws configure set sso_account_id 971119963968 --profile ghilbut-tofu-apply-for-ultary-domains
aws configure set sso_role_name TofuApplyForUltaryDomains --profile ghilbut-tofu-apply-for-ultary-domains
aws configure set region us-east-1 --profile ghilbut-tofu-apply-for-ultary-domains
```

## Apply bucket policy

```sh
export AWS_PROFILE=ghilbut-tofu-apply-for-workloads
export AWS_SDK_LOAD_CONFIG=1

tofu -chdir=aws/foundation/state/tofu init -reconfigure
tofu -chdir=aws/foundation/state/tofu plan
tofu -chdir=aws/foundation/state/tofu apply
```

Apply 후 각 root에서 `tofu state list`와 `tofu plan`을 실행한다.
