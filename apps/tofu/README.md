# Applications OpenTofu

이 루트는 플랫폼 애플리케이션의 AWS 인프라를 관리한다. 현재는 Vault가 AWS IAM Roles Anywhere를 통해 AWS KMS seal key를 사용할 수 있도록 `awsra` 모듈을 구성한다.

## 구성

- `modules/awsra/`: IAM Roles Anywhere trust anchor, IAM role, profile을 만들고 CPA context의 `awsra` Secret을 적용한다. 이 Secret에는 PKCS#8 passphrase와 leaf 인증서·개인 키가 포함된다. `awsra-cm.yaml` ConfigMap을 만든다.
- `modules/vault/`: Vault AWS KMS seal key, alias, AWSRA 역할의 KMS 권한을 만들고 `vault-cm.yaml` ConfigMap을 만든다.
- `pki/issuers/awsra-issuing-ca/ca.crt.pem`: trust anchor에 등록할 Issuing CA 인증서다.
- `pki/leaves/awsra-for-k3s-cpa/`: `awsra-for-k3s-cpa` leaf 인증서와 개인 키를 보관한다. OpenTofu는 이 개인 키를 읽지 않는다.

IAM 역할은 Issuing CA가 발급하고 Common Name이 `awsra-for-k3s-cpa`인 인증서만 사용할 수 있다. Vault AWS KMS seal key에는 `kms:Encrypt`, `kms:Decrypt`, `kms:DescribeKey`만 허용한다.

## 사용

`tofu init`과 `tofu plan`을 실행한다. Vault AWS KMS seal key는 이 루트가 생성한다.

`tofu apply`는 CPA context에 `awsra` Secret을 적용하고, 모듈에서 생성한 값으로 `apps/argo-apps/vault/awsra-cm.yaml`과 `apps/argo-apps/vault/vault-cm.yaml`을 생성한다. 두 ConfigMap은 Git에서 관리한다. PKCS#8 passphrase는 Kubernetes provider의 write-only 필드로 적용하므로 Terraform state에 저장되지 않는다. leaf 인증서와 개인 키는 Kubernetes Secret 등 배포 환경의 비밀 저장소로 별도로 전달한다.

Vault chart는 Raft storage용 10Gi PVC를 생성한다. CPA cluster에는 기본 StorageClass가 있어야 한다. Argo CD가 `vault` namespace를 먼저 생성한 뒤 OpenTofu를 적용하고, 생성된 ConfigMap을 커밋·동기화한다.
