---
title: Verify CDN in Platform
type: run
area: aws-cdn
issue: 98
status: complete
---

# Verify CDN in Platform

이 Runbook은 Platform 계정의 `oidc.k3s.ghilbut.com` CDN과 Domains 계정의 Route 53 record를
확인한다.

## 실행 값

| 항목 | 값 |
|---|---|
| Platform account | `012646747332` |
| Domains account | `869061964712` |
| Platform profile | `ghilbut-tofu-apply-for-workloads` |
| Domains profile | `ghilbut-tofu-apply-for-domains` |
| bucket | `ghilbut-cdn-platform` |
| distribution | `E1T2QAKDOSQYWI` |
| distribution domain | `d39zkdr684zql3.cloudfront.net` |
| hostname | `oidc.k3s.ghilbut.com` |
| GitHub Actions role | `arn:aws:iam::012646747332:role/cdn-platform-github-actions` |

## 1. Platform CDN 확인

```sh
AWS_PROFILE=ghilbut-tofu-apply-for-workloads \
  aws cloudfront get-distribution \
    --id E1T2QAKDOSQYWI \
    --query 'Distribution.{Status:Status,Aliases:DistributionConfig.Aliases.Items,DomainName:DomainName}'

AWS_PROFILE=ghilbut-tofu-apply-for-workloads \
  aws s3api list-objects-v2 \
    --bucket ghilbut-cdn-platform \
    --query 'Contents[].Key'
```

distribution 상태는 `Deployed`이고 alias는 `oidc.k3s.ghilbut.com` 하나다. bucket에는 다음
object가 있다.

- `404.html`
- `503.html`
- `lambda.zip`
- `oidc.k3s.ghilbut.com/cpa/.well-known/openid-configuration`
- `oidc.k3s.ghilbut.com/cpa/openid/v1/jwks`

## 2. 공개 OIDC 확인

```sh
curl --fail --silent --show-error \
  'https://oidc.k3s.ghilbut.com/cpa/.well-known/openid-configuration' \
  | jq -e \
      '.issuer == "https://oidc.k3s.ghilbut.com/cpa" and
       .jwks_uri == "https://oidc.k3s.ghilbut.com/cpa/openid/v1/jwks"'

curl --fail --silent --show-error \
  'https://oidc.k3s.ghilbut.com/cpa/openid/v1/jwks' \
  | jq -e '.keys | length > 0'
```

## 3. Domains DNS 확인

```sh
domains_credentials=$(aws sts assume-role \
  --profile ghilbut-tofu-apply-for-domains \
  --role-arn arn:aws:iam::869061964712:role/tofu-apply-domains \
  --role-session-name verify-platform-cdn)
export AWS_ACCESS_KEY_ID=$(jq -r '.Credentials.AccessKeyId' <<<"$domains_credentials")
export AWS_SECRET_ACCESS_KEY=$(jq -r '.Credentials.SecretAccessKey' <<<"$domains_credentials")
export AWS_SESSION_TOKEN=$(jq -r '.Credentials.SessionToken' <<<"$domains_credentials")

aws route53 list-resource-record-sets \
  --hosted-zone-id Z193YX3H31OEZV

unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
```

`oidc.k3s.ghilbut.com` A alias는 `d39zkdr684zql3.cloudfront.net`을 가리킨다. ACM validation
CNAME은 Platform certificate의 세 record만 유지한다.

## 4. 배포 경로 확인

```sh
gh variable set AWS_IAM_ROLE_CDN_GITHUB_ACTIONS_ARN \
  --repo ghilbut/platform \
  --body 'arn:aws:iam::012646747332:role/cdn-platform-github-actions'

gh api repos/ghilbut/platform/actions/variables/AWS_IAM_ROLE_CDN_GITHUB_ACTIONS_ARN

AWS_PROFILE=ghilbut-tofu-apply-for-workloads \
  tofu -chdir=aws/cdn/tofu plan
```

Certificate의 wildcard SAN은 다음 parallel distribution 검증용 hostname을 지원한다. Distribution
alias는 `oidc.k3s.ghilbut.com` 하나만 유지한다.

repository variable 값은 `arn:aws:iam::012646747332:role/cdn-platform-github-actions`다.
GitHub Actions는 workload role을 직접 사용하므로 `TF_VAR_aws_execution_role_arn`을 빈 문자열로
지정한다. 로컬 작업은 기본값인 `arn:aws:iam::012646747332:role/tofu-apply`를 수임한다.

## 5. State 확인

```sh
AWS_PROFILE=ghilbut-tofu-apply-for-workloads \
  tofu -chdir=aws/cdn/tofu state list
AWS_PROFILE=ghilbut-tofu-apply-for-workloads \
  tofu -chdir=github/tofu plan
AWS_PROFILE=ghilbut-tofu-apply-for-workloads \
  tofu -chdir=aws/foundation/state/tofu plan
AWS_PROFILE=ghilbut-tofu-apply-for-workloads \
  tofu -chdir=k3s/tofu state list
```

CDN state의 module 이름은 `certificate`, `s3`, `edge`, `cloudfront`, `origin_access`,
`github_actions`다. K3s state에는 기존 bucket의 OIDC object 주소가 없다.

## 6. Domains CDN 제거 확인

```sh
workload_credentials=$(aws sts assume-role \
  --profile ghilbut-tofu-apply-for-workloads-domains \
  --role-arn arn:aws:iam::869061964712:role/tofu-apply \
  --role-session-name verify-removed-cdn)
export AWS_ACCESS_KEY_ID=$(jq -r '.Credentials.AccessKeyId' <<<"$workload_credentials")
export AWS_SECRET_ACCESS_KEY=$(jq -r '.Credentials.SecretAccessKey' <<<"$workload_credentials")
export AWS_SESSION_TOKEN=$(jq -r '.Credentials.SessionToken' <<<"$workload_credentials")

aws cloudfront get-distribution --id E1FNHJ17EQ6KS9
aws s3api head-bucket --bucket ghilbut-platform-cdn
aws lambda get-function \
  --region us-east-1 \
  --function-name platform-cdn-origin-request
aws iam get-role --role-name platform-cdn-github-actions

unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
```

각 명령은 대상이 없다는 응답을 반환한다. Domains 계정의 `tofu-apply` 역할은 Issue #99가
관리한다.
