---
title: Domains execution and CDN DNS ownership runbook
type: runbook
area: domains
tags:
  - aws
  - route53
  - opentofu
---

# Domains execution and CDN DNS ownership runbook

이 Runbook은 `TofuApplyForDomains` source identity와 `tofu-apply-domains` 실행 역할을 연결하고,
CDN의 Route 53 record 세 개를 Domains state로 옮긴다. state object와 lock file을 S3 API로
복사하지 않는다. Route 53 record는 삭제하거나 다시 만들지 않는다.

## 대상

| 현재 address | Domains address | Import ID |
|---|---|---|
| `module.certificate.aws_route53_record.validation["ghilbut.com"]` | `aws_route53_record.cdn_certificate_validation["ghilbut.com"]` | `Z193YX3H31OEZV__1f3bc0e46ca05d312b303b35e6c8d69b.ghilbut.com._CNAME` |
| `module.certificate.aws_route53_record.validation["oidc.k3s.ghilbut.com"]` | `aws_route53_record.cdn_certificate_validation["oidc.k3s.ghilbut.com"]` | `Z193YX3H31OEZV__249f0cc45cee4112146a0bb348aa145a.oidc.k3s.ghilbut.com._CNAME` |
| `module.dns.aws_route53_record.this["oidc.k3s.ghilbut.com"]` | `aws_route53_record.cdn_alias["oidc.k3s.ghilbut.com"]` | `Z193YX3H31OEZV_oidc.k3s.ghilbut.com_A` |

## 1. Bootstrap 적용

Bootstrap commit은 다음 변경만 포함한다.

- Domains state에 `tofu-apply-domains` 역할을 추가한다.
- Domains source identity에 CDN state object 읽기 권한을 추가한다.
- Platform state bucket policy에 같은 읽기 권한을 추가한다.
- CDN state에 certificate validation option, FQDN, CloudFront domain과 hosted zone ID output을
  추가한다.
- Domains provider는 source credential을 직접 사용한다.

`tofu-apply-domains` 역할과 역할 정책은 자기 자신에게 IAM 변경 권한을 주지 않는다. 이 역할과
역할 정책을 만들거나 변경할 때는 임시 Bootstrap 경로인
`ghilbut-tofu-apply-for-workloads-domains` profile을 사용한다. Backend는
`ghilbut-tofu-apply-for-domains` profile을 사용한다.

```sh
export AWS_SDK_LOAD_CONFIG=1

AWS_PROFILE=ghilbut-tofu-apply-for-workloads-domains \
  tofu -chdir=domains/tofu plan
AWS_PROFILE=ghilbut-tofu-apply-for-workloads-domains \
  tofu -chdir=domains/tofu apply

AWS_PROFILE=ghilbut-tofu-apply-for-workloads \
  tofu -chdir=aws/foundation/state/tofu plan
AWS_PROFILE=ghilbut-tofu-apply-for-workloads \
  tofu -chdir=aws/foundation/state/tofu apply

AWS_PROFILE=ghilbut-tofu-apply-for-management \
  tofu -chdir=aws/foundation/identity/tofu plan
AWS_PROFILE=ghilbut-tofu-apply-for-management \
  tofu -chdir=aws/foundation/identity/tofu apply

AWS_PROFILE=ghilbut-tofu-apply-for-workloads-domains \
  tofu -chdir=aws/cdn/tofu plan
AWS_PROFILE=ghilbut-tofu-apply-for-workloads-domains \
  tofu -chdir=aws/cdn/tofu apply
```

`aws iam get-role --role-name tofu-apply-domains`가 역할을 반환해야 한다. CDN state output에는
`certificate_validation_options`, `fqdns`, `cloudfront_domain_name`,
`cloudfront_hosted_zone_id`가 있어야 한다.

## 2. 최종 실행 경로 적용

최종 commit은 다음 변경을 포함한다.

- `TofuApplyForDomains`에서 직접 Route 53 정책을 제거한다.
- source identity에는 v2의 Domains state read/write, CDN state read-only,
  `tofu-apply-domains` 수임만 허용한다.
- Domains provider는 `tofu-apply-domains`를 수임한다.
- Domains root는 `ghilbut-tofu-apply-for-domains` profile로 CDN state를 읽고 validation record와
  alias를 선언한다.
- CDN root는 Route 53 resource를 state에서만 제거하고 Route 53 변경 권한을 제거한다.
- CDN certificate validation resource는 ACM validation option의 record name을 직접 사용한다.

Identity 변경을 먼저 적용한다. 이어서 caller와 실행 역할을 확인한다.

```sh
AWS_PROFILE=ghilbut-tofu-apply-for-management \
  tofu -chdir=aws/foundation/identity/tofu plan
AWS_PROFILE=ghilbut-tofu-apply-for-management \
  tofu -chdir=aws/foundation/identity/tofu apply

AWS_PROFILE=ghilbut-tofu-apply-for-domains aws sts get-caller-identity
AWS_PROFILE=ghilbut-tofu-apply-for-domains \
  aws sts assume-role \
  --role-arn arn:aws:iam::869061964712:role/tofu-apply-domains \
  --role-session-name verify-domains-execution
```

## 3. State 소유권 이동

CDN plan은 세 Route 53 record를 `destroy = false`로 state에서 제거해야 한다. Domains plan은
같은 세 record를 import해야 한다. 두 plan 모두 Route 53 create, update, delete를 포함하지
않아야 한다.

CDN plan을 먼저 적용하고 즉시 Domains import plan을 적용한다.

```sh
AWS_PROFILE=ghilbut-tofu-apply-for-workloads-domains \
  tofu -chdir=aws/cdn/tofu plan -out=cdn-dns-release.tfplan
AWS_PROFILE=ghilbut-tofu-apply-for-domains \
  tofu -chdir=domains/tofu plan -out=domains-dns-import.tfplan

AWS_PROFILE=ghilbut-tofu-apply-for-workloads-domains \
  tofu -chdir=aws/cdn/tofu apply cdn-dns-release.tfplan
AWS_PROFILE=ghilbut-tofu-apply-for-domains \
  tofu -chdir=domains/tofu apply domains-dns-import.tfplan
```

적용 후 CDN state에는 `aws_route53_record`가 없어야 한다. Domains state에는 대상 표의 address
세 개가 모두 있어야 한다. Route 53 API가 반환하는 name, type, value, alias target은 적용 전
값과 같아야 한다.

## 4. 새 CDN의 두 단계 적용

새 certificate와 distribution을 만들 때 다음 순서를 사용한다.

1. CDN root에서 ACM certificate만 명시적으로 선택해 만든다.
2. Domains root가 CDN state의 validation option으로 CNAME record를 만든다.
3. CDN root가 certificate validation과 CloudFront distribution을 완료한다.
4. Domains root가 CDN state의 CloudFront domain과 hosted zone ID로 alias를 전환한다.

```sh
AWS_PROFILE=ghilbut-tofu-apply-for-workloads-domains \
  tofu -chdir=aws/cdn/tofu plan \
  -target=module.certificate.aws_acm_certificate.this \
  -out=cdn-certificate.tfplan
AWS_PROFILE=ghilbut-tofu-apply-for-workloads-domains \
  tofu -chdir=aws/cdn/tofu apply cdn-certificate.tfplan
```

CDN root는 Route 53 record를 선언하지 않는다. Domains root만 hosted zone과 record를 변경한다.
