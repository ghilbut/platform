---
type: guide
area: apps
---

# Applications OpenTofu

이 root는 AWS 리소스를 관리하지 않는다. CPA 애플리케이션의 AWS IAM federation은
[Domains OpenTofu](../../domains/tofu/)가 관리한다.

Apps state의 관리 리소스는 0개다.

Backend는 Plan에서 SharedServices `tofu-state-readonly`, Apply에서 SharedServices
`tofu-state-apply`를 수임한다. Provider의 기본 execution role은 SharedServices `tofu-plan`이다.
Backend와 provider는 같은 Workloads source profile을 사용한다. Apply 전용 로컬 작업 공간은
`apps/tofu/tofu-apply.auto.tfvars`에 다음 값을 지정한다.

```hcl
aws_execution_role_arn = "arn:aws:iam::012646747332:role/tofu-apply"
```
