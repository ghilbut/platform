---
type: guide
area: k3s
cluster: cpa
---

# CPA ServiceAccount OIDC와 AWS IAM Federation

CPA K3s는 ServiceAccount token issuer로 `https://oidc.k3s.ghilbut.com/cpa`를 사용한다. 이 issuer는 AWS IAM이 CPA workload의 short-lived token을 검증하도록 만든다.

## 공개 범위

공개 endpoint는 discovery 문서와 JWKS뿐이다.

| URL | 공개하는 정보 |
| --- | --- |
| `https://oidc.k3s.ghilbut.com/cpa/.well-known/openid-configuration` | issuer와 JWKS URL |
| `https://oidc.k3s.ghilbut.com/cpa/openid/v1/jwks` | token 서명 public key |

ServiceAccount token, Kubernetes Secret, token 서명 private key는 공개하지 않는다. token은 Kubernetes API의 TokenRequest로 발급되어 Pod의 projected volume에만 전달된다.

## 구성과 변경 추적

K3s 설치 시 `service-account-issuer`와 `service-account-jwks-uri`에 이 issuer를 설정한다. 상세 절차는 [K3s 설치 RUNBOOK](RUNBOOK.md#b-server)의 server 설치를 따른다. CPA의 적용 값은 [CPA 설치 기록](RUN-CPA-2026-05-18.md#1-범위)에 기록한다.

`k3s/tofu`는 Kubernetes API에서 discovery 문서와 JWKS를 읽어 CDN object로 동기화한다. 공개 endpoint의 CDN과 object 경로는 [AWS CDN](../aws/cdn/README.md)을 따른다.

## AWS IAM federation 경계

platform 계정에는 CPA issuer당 IAM OIDC provider를 하나만 만든다. 이 provider는 모든 CPA workload가 공유할 수 있는 token 검증 진입점이다.

| IAM OIDC provider 설정 | 값 |
| --- | --- |
| issuer URL | `https://oidc.k3s.ghilbut.com/cpa` |
| client ID | `sts.amazonaws.com` |
| TLS intermediate CA SHA-1 thumbprint | `e7b8b5a6743ce1b2f17b041de59558a41472d70c` |

thumbprint는 `apps/tofu`의 `cpa_oidc_thumbprint`로 관리한다. CDN TLS 인증서의 intermediate CA가 바뀌면 새 thumbprint를 확인하고 이 값을 갱신한다.

각 workload는 IAM 역할을 공유하지 않는다. 역할 trust policy는 다음을 모두 지정한다.

1. `sts:AssumeRoleWithWebIdentity` action
2. `sts.amazonaws.com` audience
3. 정확한 `system:serviceaccount:<namespace>:<serviceaccount>` subject

Vault, cert-manager, external-dns, 백업 workload의 역할과 권한은 [Applications OpenTofu](../apps/tofu/README.md#iam-federation-경계)에서 관리한다. 각 역할에는 필요한 AWS 리소스 권한만 부여한다.

## 운영 확인

1. discovery 문서의 `issuer`와 JWKS URL이 위 URL과 일치하는지 확인한다.
2. IAM OIDC provider의 issuer URL, `sts.amazonaws.com` client ID, TLS intermediate CA thumbprint를 확인한다.
3. workload가 audience `sts.amazonaws.com`의 projected token을 mount하고 `AWS_ROLE_ARN`, `AWS_WEB_IDENTITY_TOKEN_FILE`을 설정하는지 확인한다.
4. 역할 trust policy의 subject가 workload ServiceAccount와 정확히 일치하는지 확인한다.
5. CloudTrail의 `AssumeRoleWithWebIdentity`와 대상 AWS API 호출을 확인한다.
