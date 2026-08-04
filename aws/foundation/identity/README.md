---
title: IAM Identity Center
---

# IAM Identity Center

`tofu/`는 IAM Identity Center permission set과 AWS 계정 할당을 관리한다.

| Permission set | 대상 계정 | Principal | 책임 |
|---|---|---|---|
| `FoundationManagement` | management | `DevOps` 그룹 | Organizations, 계정, 결제, IAM Identity Center 관리 |
| `TofuApplyForManagement` | management | `DevOps` 그룹 | Management 계정 OpenTofu 적용 |
| `TofuApplyForDomains` | domains | `DevOps` 그룹 | Domains Route 53 관리 |
| `TofuApplyForWorkloads` | domains, platform | `DevOps` 그룹 | 계정 분리 중 기존 워크로드와 새 Platform 관리 |
| `TofuApplyForUltaryDomains` | UltaryDomains | `DevOps` 그룹 | Ultary Domains Route 53 관리 |

## OpenTofu 실행 역할

IAM Identity Center permission set은 사람 또는 CI의 최초 인증에만 사용한다. OpenTofu는
별도 IAM 실행 역할을 수임해 AWS 리소스를 관리한다. permission set 이름이 바뀌지 않아도
AWS가 생성하는 `AWSReservedSSO` 역할의 suffix는 바뀔 수 있으므로, 실행 역할의 신뢰 정책은
permission set 이름과 역할 경로를 조건으로 사용한다.

각 최초 인증 permission set은 표에 있는 실행 역할만 `sts:AssumeRole`로 수임한다.
계정 분리 중 `TofuApplyForWorkloads`는 Domains와 Platform의 같은 이름 역할을 수임한다.
`TofuApplyForManagement`는 Foundation accounts·identity state와 lock file의 S3 접근도
가진다. `TofuApplyForWorkloads`는 workload bootstrap state와 lock file에 접근한다.

| 최초 인증 permission set | 실행 역할 | 관리 state |
|---|---|---|
| `TofuApplyForManagement` | `tofu-apply` | Foundation identity와 accounts |
| `TofuApplyForWorkloads` | Domains `tofu-apply` | 기존 CDN과 workload |
| `TofuApplyForWorkloads` | Platform `tofu-apply` | Platform |

## CLI source profile

각 `TofuApply*` permission set은 별도의 source profile로 로그인한다. Foundation backend는
`TofuApplyForManagement` source profile로 state에 접근하고, provider는 Management
`tofu-apply` 역할을 수임한다. 계정 분리 중 Domains workload는
`ghilbut-tofu-apply-for-workloads-domains`, 새 Platform은
`ghilbut-tofu-apply-for-workloads`를 사용한다.

`FoundationManagement`는 AWS access portal에서 Management 계정의 콘솔 접근에 사용한다.
다음 명령은 repository root에서 실행한다.

```sh
aws configure set sso_session ghilbut --profile ghilbut-tofu-apply-for-management
aws configure set sso_account_id 384959722788 --profile ghilbut-tofu-apply-for-management
aws configure set sso_role_name TofuApplyForManagement --profile ghilbut-tofu-apply-for-management
aws configure set region us-east-1 --profile ghilbut-tofu-apply-for-management

aws configure set sso_session ghilbut --profile ghilbut-tofu-apply-for-domains
aws configure set sso_account_id 869061964712 --profile ghilbut-tofu-apply-for-domains
aws configure set sso_role_name TofuApplyForDomains --profile ghilbut-tofu-apply-for-domains
aws configure set region us-east-1 --profile ghilbut-tofu-apply-for-domains

aws configure set sso_session ghilbut --profile ghilbut-tofu-apply-for-workloads-domains
aws configure set sso_account_id 869061964712 --profile ghilbut-tofu-apply-for-workloads-domains
aws configure set sso_role_name TofuApplyForWorkloads --profile ghilbut-tofu-apply-for-workloads-domains
aws configure set region us-east-1 --profile ghilbut-tofu-apply-for-workloads-domains

aws sso login --profile ghilbut-tofu-apply-for-management
platform_account_id="$(AWS_PROFILE=ghilbut-tofu-apply-for-management tofu -chdir=aws/foundation/accounts/tofu output -raw platform_account_id)"
aws configure set sso_session ghilbut --profile ghilbut-tofu-apply-for-workloads
aws configure set sso_account_id "${platform_account_id}" --profile ghilbut-tofu-apply-for-workloads
aws configure set sso_role_name TofuApplyForWorkloads --profile ghilbut-tofu-apply-for-workloads
aws configure set region us-east-1 --profile ghilbut-tofu-apply-for-workloads

aws configure set sso_session ghilbut --profile ghilbut-tofu-apply-for-ultary-domains
aws configure set sso_account_id 971119963968 --profile ghilbut-tofu-apply-for-ultary-domains
aws configure set sso_role_name TofuApplyForUltaryDomains --profile ghilbut-tofu-apply-for-ultary-domains
aws configure set region us-east-1 --profile ghilbut-tofu-apply-for-ultary-domains

aws sts get-caller-identity --profile ghilbut-tofu-apply-for-management
aws sso login --profile ghilbut-tofu-apply-for-domains
aws sts get-caller-identity --profile ghilbut-tofu-apply-for-domains
aws sso login --profile ghilbut-tofu-apply-for-workloads-domains
aws sts get-caller-identity --profile ghilbut-tofu-apply-for-workloads-domains
aws sso login --profile ghilbut-tofu-apply-for-workloads
aws sts get-caller-identity --profile ghilbut-tofu-apply-for-workloads
aws sso login --profile ghilbut-tofu-apply-for-ultary-domains
aws sts get-caller-identity --profile ghilbut-tofu-apply-for-ultary-domains
```

permission set 할당은 계정 책임과 운영 인원에 따라 사용자 직접 할당 또는 그룹 할당을
선택한다.
