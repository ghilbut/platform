---
type: guide
area: apps
---

# Applications OpenTofu

이 루트는 플랫폼 애플리케이션의 AWS 인프라를 관리한다. `k3s/tofu`가 등록한 CPA ServiceAccount IAM OIDC provider를 사용해 애플리케이션별 IAM 역할과 권한을 분리한다.

애플리케이션 문서의 진입점은 [Applications](../README.md)다.

CPA OIDC issuer의 공개와 Kubernetes 설정은 [[k3s/RUNBOOK#D. ServiceAccount OIDC와 AWS IAM federation|K3s ServiceAccount OIDC RUNBOOK]]에서, CPA의 실제 설치 값은 [[k3s/runbooks/CPA|CPA 실행 Runbook]]에서 확인한다.

## IAM federation 경계

| 구분 | 소유 위치 | 범위 |
| --- | --- | --- |
| CPA OIDC issuer | [[k3s/RUNBOOK#D. ServiceAccount OIDC와 AWS IAM federation|K3s ServiceAccount OIDC RUNBOOK]] | ServiceAccount token의 issuer, discovery 문서, JWKS 공개 |
| IAM OIDC provider | [K3s OpenTofu](../../k3s/tofu/) | `https://oidc.k3s.ghilbut.com/cpa`를 신뢰하는 platform 계정의 공용 federation 진입점 |
| IAM 역할과 권한 정책 | 애플리케이션 module | 한 ServiceAccount와 그 workload에 필요한 AWS 리소스만 허용 |

OIDC discovery 문서와 JWKS는 공개 정보이며 ServiceAccount token이나 Kubernetes Secret을 공개하지 않는다. token 서명 private key와 각 Pod의 projected token은 Kubernetes 내부에서 보호한다.

## Vault 구성

- `modules/vault/`: Vault AWS KMS seal key, alias, `platform-vault` IAM 역할과 KMS 권한을 만든다.
- Vault 역할은 `system:serviceaccount:vault:vault` subject와 `sts.amazonaws.com` audience를 모두 요구한다.
- Vault Helm chart는 projected ServiceAccount token을 `AWS_WEB_IDENTITY_TOKEN_FILE`로 전달한다. EKS 전용 webhook을 사용하지 않는다.

Vault AWS KMS seal key에는 `kms:Encrypt`, `kms:Decrypt`, `kms:DescribeKey`만 허용한다. Vault 초기화와 수동 snapshot은 [Vault 운영 RUNBOOK](../docs/vault/RUNBOOK.md)을 따르고, snapshot 복원과 workload 이전은 [Vault 복구 PLAYBOOK](../docs/vault/PLAYBOOK.md)을 따른다.

## 사용

`k3s/tofu`에서 IAM OIDC provider를 먼저 적용한 뒤 이 root에서 `tofu init`과 `tofu plan`을 실행한다. Vault AWS KMS seal key와 Vault IAM 역할은 이 root가 생성한다.

추가 workload는 공용 IAM OIDC provider를 재사용하되, 역할을 공유하지 않는다. cert-manager, external-dns, 백업 workload는 각각의 namespace·ServiceAccount subject와 필요한 Route 53, S3 또는 기타 권한만 가진 별도 module을 추가한다.

Vault chart의 StatefulSet은 `data-vault-0` PVC를 사용한다. PVC는 chart보다 앞선 sync wave에서 생성되며, Vault Application 삭제와 Git prune에서 제외된다. CPA cluster에는 `openebs-lvm` StorageClass가 있어야 한다.

## cert-manager 구성

- `modules/cert-manager/`는 `cert_manager_clusters`의 cluster마다 `platform-<cluster>-cert-manager` IAM 역할을 만든다. 현재 root는 CPA에 `ghilbut.com`, `ghilbut.net` Route 53 DNS-01 권한을 부여한다.
- 각 역할은 해당 cluster의 OIDC issuer와 지정한 ServiceAccount subject, `sts.amazonaws.com` audience를 모두 요구한다.
- 각 cluster의 ClusterIssuer는 bound ServiceAccount token으로 STS를 호출한다. 장기 AWS access key Kubernetes Secret과 controller ambient credential을 사용하지 않는다.

## external-dns 구성

- `modules/external-dns/`는 `external_dns_clusters`의 cluster마다 `platform-<cluster>-external-dns` IAM 역할을 만든다. 현재 root는 CPA의 `id.ghilbut.com` CNAME과 TXT ownership record만 변경할 수 있다.
- 각 역할은 해당 cluster의 OIDC issuer와 지정한 ServiceAccount subject, `sts.amazonaws.com` audience를 모두 요구한다.
- `policy: sync`는 Gateway에서 hostname을 제거하면 같은 owner ID의 record와 TXT ownership record를 함께 삭제한다. 다른 owner ID 또는 선언하지 않은 record는 변경하지 않는다.
