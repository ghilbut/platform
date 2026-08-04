# IAM Identity Center

`aws/foundation/identity/tofu/`는 permission set, DevOps group과 account assignment를
관리한다.

## Permission sets

| Permission set | Account | Purpose |
|---|---|---|
| `FoundationManagement` | Management | AWS access portal의 Management console access |
| `TofuApplyForManagement` | Management | Foundation account와 identity OpenTofu |
| `TofuApplyForDomains` | Domains | Domains state와 `tofu-apply-domains` |
| `TofuApplyForWorkloads` | Platform | Platform workload state와 `tofu-apply` |
| `TofuApplyForUltaryDomains` | UltaryDomains | UltaryDomains state와 Route 53 |

`TofuApplyForWorkloads`는 Platform account `012646747332`에만 할당한다.
`TofuApplyForDomains`는 Domains account `869061964712`에만 할당한다.

## Source profiles

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

## Apply

```sh
export AWS_PROFILE=ghilbut-tofu-apply-for-management
export AWS_SDK_LOAD_CONFIG=1

tofu -chdir=aws/foundation/identity/tofu init -reconfigure
tofu -chdir=aws/foundation/identity/tofu plan
tofu -chdir=aws/foundation/identity/tofu apply
```

Apply 후 IAM Identity Center provisioning status가 `SUCCEEDED`인지 확인한다.
