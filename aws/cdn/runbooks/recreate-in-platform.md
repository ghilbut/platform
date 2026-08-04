---
title: Recreate CDN in Platform
type: run
area: aws-cdn
issue: 98
status: running
---

# Recreate CDN in Platform

이 Runbook은 `oidc.k3s.ghilbut.com` CDN을 Platform 계정에 만들고 Domains 계정의 기존 CDN을
삭제한다. Route 53 hosted zone과 record는 Domains가 관리한다.

현재 실행 가능한 범위는 1단계다. 다음 단계의 OpenTofu 구성과 저장된 계획을 준비한 뒤 해당
단계를 실행한다.

## 실행 값

| 항목 | 값 |
|---|---|
| Domains account | `869061964712` |
| Platform account | `012646747332` |
| Domains source profile | `ghilbut-tofu-apply-for-workloads-domains` |
| Platform source profile | `ghilbut-tofu-apply-for-workloads` |
| 기존 bucket | `ghilbut-platform-cdn` |
| 새 bucket | `ghilbut-cdn-platform` |
| 기존 distribution | `E1FNHJ17EQ6KS9` |
| hostname | `oidc.k3s.ghilbut.com` |
| 임시 wildcard | `*.k3s.ghilbut.com` |

AWS는 활성화된 교차 계정 CloudFront distribution 사이의 subdomain 이전에 wildcard 절차를
지원한다. [CloudFront alternate domain name 이전](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/alternate-domain-names-move-options.html)을 따른다.

## 1. Platform federation과 certificate 요청

1. `github/tofu`에서 기존 Domains GitHub Actions OIDC provider를 유지하고 Platform provider를
   추가한다.
2. GitHub provider가 repository variable을 읽을 수 없으므로 `gh`로 현재 값을 확인하고 CDN
   state에서 variable 주소만 해제한다. 원격 variable은 유지한다.
3. `aws/cdn/tofu`에서 Platform ACM certificate만 요청한다. certificate는 `ghilbut.com`,
   `oidc.k3s.ghilbut.com`, `*.k3s.ghilbut.com`을 포함한다.
4. 두 계획이 각각 `1 add, 0 change, 0 destroy`인지 확인하고 적용한다.

CDN state 해제 전 version ID는 `NsxgJxqZ1HA4Rn2YLpbKQ6e6x3prPhp1`이다. state 주소 복구가
필요하면 이 version을 현재 `platform/aws/cdn.tfstate`로 복원한다.

```sh
AWS_SDK_LOAD_CONFIG=1 AWS_PROFILE=ghilbut-tofu-apply-for-workloads-domains \
  tofu -chdir=github/tofu plan \
    -out=/tmp/issue-98-github-platform-oidc.tfplan

gh api repos/ghilbut/platform/actions/variables/AWS_IAM_ROLE_CDN_GITHUB_ACTIONS_ARN
AWS_SDK_LOAD_CONFIG=1 AWS_PROFILE=ghilbut-tofu-apply-for-workloads \
  tofu -chdir=aws/cdn/tofu state rm -dry-run \
    'module.github_actions.github_actions_variable.cdn_role_arn'
AWS_SDK_LOAD_CONFIG=1 AWS_PROFILE=ghilbut-tofu-apply-for-workloads \
  tofu -chdir=aws/cdn/tofu state rm \
    'module.github_actions.github_actions_variable.cdn_role_arn'

AWS_SDK_LOAD_CONFIG=1 AWS_PROFILE=ghilbut-tofu-apply-for-workloads \
  tofu -chdir=aws/cdn/tofu plan \
    -target='module.certificate_platform.aws_acm_certificate.this' \
    -out=/tmp/issue-98-platform-certificate-request.tfplan

AWS_SDK_LOAD_CONFIG=1 AWS_PROFILE=ghilbut-tofu-apply-for-workloads-domains \
  tofu -chdir=github/tofu apply /tmp/issue-98-github-platform-oidc.tfplan
AWS_SDK_LOAD_CONFIG=1 AWS_PROFILE=ghilbut-tofu-apply-for-workloads \
  tofu -chdir=aws/cdn/tofu apply /tmp/issue-98-platform-certificate-request.tfplan
```

## 2. Platform certificate 검증

1. Domains root가 CDN remote state의 `platform_certificate_validation_options`를 읽는다.
2. Platform certificate의 CNAME record만 추가한다.
3. Domains 계획을 적용하고 Platform certificate 상태가 `ISSUED`인지 확인한다.

```sh
AWS_PROFILE=ghilbut-tofu-apply-for-domains \
  tofu -chdir=domains/tofu plan \
    -out=/tmp/issue-98-platform-certificate-validation.tfplan
AWS_PROFILE=ghilbut-tofu-apply-for-domains \
  tofu -chdir=domains/tofu apply /tmp/issue-98-platform-certificate-validation.tfplan
```

## 3. Platform CDN 생성과 검증

1. Platform 계정에 `ghilbut-cdn-platform` bucket, Lambda@Edge, CloudFront Function,
   distribution, OAC, GitHub Actions 역할을 만든다.
2. 새 distribution에는 `*.k3s.ghilbut.com`만 연결한다. 정확한 hostname은 기존 distribution에
   유지한다.
3. 기존 bucket의 OIDC discovery document와 JWKS를 새 bucket에 복사한다.
4. 새 distribution domain에 `Host: oidc.k3s.ghilbut.com`을 보내 두 document의 내용과 응답
   상태를 확인한다.

```sh
AWS_SDK_LOAD_CONFIG=1 AWS_PROFILE=ghilbut-tofu-apply-for-workloads \
  tofu -chdir=aws/cdn/tofu plan \
    -out=/tmp/issue-98-platform-cdn-create.tfplan
AWS_SDK_LOAD_CONFIG=1 AWS_PROFILE=ghilbut-tofu-apply-for-workloads \
  tofu -chdir=aws/cdn/tofu apply /tmp/issue-98-platform-cdn-create.tfplan
```

## 4. CloudFront hostname 전환

1. Domains Route 53에 `_oidc.k3s.ghilbut.com` TXT record를 만들고 값으로 새 distribution
   domain을 지정한다.
2. `oidc.k3s.ghilbut.com` A alias를 새 distribution으로 바꾼다. CloudFront는 기존 exact
   hostname을 계속 우선하므로 이 단계는 기존 distribution으로 요청을 전달한다.
3. 기존 distribution에서 exact hostname을 제거하고 `Deployed` 상태를 확인한다. 요청은 새
   distribution의 wildcard로 전달된다.
4. 새 distribution에 exact hostname을 추가하고 wildcard를 제거한다.
5. DNS, TLS, discovery document, JWKS를 확인한다.

3단계 뒤 검증에 실패하면 A alias를 기존 distribution으로 복원한다. 4단계에서 exact hostname
추가에 실패하면 기존 distribution에 exact hostname을 다시 추가하고 A alias를 복원한다.

## 5. 배포 경로 전환

GitHub repository variable을 새 Platform 역할 ARN으로 바꾼다. workflow 대상은 Platform CDN
module address만 사용한다.

```sh
gh variable set AWS_IAM_ROLE_CDN_GITHUB_ACTIONS_ARN \
  --repo ghilbut/platform \
  --body '<PLATFORM_GITHUB_ACTIONS_ROLE_ARN>'
```

## 6. 기존 CDN 삭제

1. K3s state의 기존 OIDC S3 object 두 주소를 dry run으로 확인하고 state에서 해제한다.
2. `k3s/tofu`의 backend와 AWS provider를 Platform source profile로 바꾸고 bucket을
   `ghilbut-cdn-platform`으로 바꾼다. 이 단계는 hostname 전환 전에 끝낸다.
3. 기존 bucket을 비운다.
4. Domains의 기존 distribution, certificate, Lambda@Edge, CloudFront Function, OAC, bucket,
   GitHub Actions 역할을 삭제한다.
5. 첫 삭제에서 Lambda@Edge replica가 남아 있으면 replica 제거를 확인한 뒤 같은 계획을 다시
   만든다.
6. Domains root에서 기존 certificate validation CNAME과 임시 TXT record를 제거한다.
7. Foundation state bucket policy에서 기존 Domains GitHub Actions 역할의 접근을 제거한다.
8. `github/tofu`에서 Domains GitHub Actions OIDC provider와 기존 output을 삭제한다.

## 7. 완료 확인

- `oidc.k3s.ghilbut.com`은 Platform distribution을 사용한다.
- Platform bucket에는 오류 문서, Lambda ZIP, OIDC discovery document, JWKS가 있다.
- GitHub repository variable은 Platform 역할 ARN이다.
- Domains에는 기존 CDN bucket, distribution, certificate, edge 함수, OAC, 배포 역할,
  GitHub Actions OIDC provider가 없다.
- Route 53 record는 Domains state만 관리한다.
- CDN, Domains, GitHub 계획에는 변경 사항이 없다.
- K3s state는 기존 Domains bucket object를 관리하지 않는다.
