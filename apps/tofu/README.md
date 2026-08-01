# Applications OpenTofu

이 루트는 플랫폼 애플리케이션의 AWS 인프라를 관리한다. 현재는 Vault가 AWS IAM Roles Anywhere를 통해 AWS KMS seal key를 사용할 수 있도록 `awsra` 모듈을 구성한다.

## 구성

- `modules/awsra/`: IAM Roles Anywhere trust anchor, IAM role, profile을 만든다.
- `modules/vault/`: Vault AWS KMS seal key, alias, AWSRA 역할의 KMS 권한을 만든다.
- `pki/issuers/awsra-issuing-ca/ca.crt.pem`: trust anchor에 등록할 Issuing CA 인증서다.
- `pki/leaves/awsra-for-k3s-cpa/`: `awsra-for-k3s-cpa` leaf 인증서와 개인 키를 보관한다. OpenTofu는 이 개인 키를 읽지 않는다.

IAM 역할은 Issuing CA가 발급하고 Common Name이 `awsra-for-k3s-cpa`인 인증서만 사용할 수 있다. Vault AWS KMS seal key에는 `kms:Encrypt`, `kms:Decrypt`, `kms:DescribeKey`만 허용한다.

## 사용

`tofu init`과 `tofu plan`을 실행한다. Vault AWS KMS seal key는 이 루트가 생성한다.

출력된 `awsra_profile_arn`, `awsra_role_arn`, `awsra_trust_anchor_arn`을 `apps/argo-apps/vault/awsra.yaml`의 같은 이름 환경 변수에 설정한다. `vault_kms_key_arn`은 Vault의 `VAULT_AWSKMS_SEAL_KEY_ID`에 설정한다. leaf 인증서와 개인 키 및 passphrase는 Kubernetes Secret 등 배포 환경의 비밀 저장소로 전달한다.
