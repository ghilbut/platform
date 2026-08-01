# PKI 룰북

## 목적과 적용 범위

이 룰북은 사설 PKI와 AWS IAM Roles Anywhere용 인증서에 적용한다. 절차와 명령은 [RUNBOOK.md](RUNBOOK.md)를, 각 실제 수행 결과는 `RUN-YYYY-mm-dd.md`를 따른다.

## 인증서 계층과 권한

```text
Root CA
  └── Intermediate CA
        └── AWS Roles Anywhere Issuing CA
              └── workload leaf 인증서
```

| 구성 요소 | 허용된 역할 | 개인 키 보관 |
| --- | --- | --- |
| Root CA | Intermediate CA 서명만 | 오프라인 보관 |
| Intermediate CA | Issuing CA 서명만 | 오프라인 보관 |
| AWS Roles Anywhere Issuing CA | AWS Roles Anywhere leaf 서명만 | 접근이 통제된 CA 환경 |
| Leaf | 자신의 AWS Roles Anywhere 요청 서명만 | 해당 workload 호스트 |

Leaf 인증서는 CA가 아니며 다른 인증서를 서명할 수 없다. 각 CA는 바로 아래 계층만 서명한다.

## 암호화와 이름 규칙

- 모든 subject에는 `C=KR`, `O=Ghilbut`을 포함한다.
- 키 알고리즘은 EC P-384, 인증서 서명은 SHA-384을 사용한다.
- 기본 유효 기간은 3,650일이다. 더 짧은 유효 기간이 서비스 또는 보안 요구사항에 필요하면 그 요구사항을 우선한다.
- Root CA, Intermediate CA, Issuing CA의 Basic Constraints는 각각 `pathlen:2`, `pathlen:1`, `pathlen:0`이다.
- AWS Roles Anywhere leaf는 `CA:FALSE`, `digitalSignature`, `clientAuth`를 사용한다.
- workload의 CN은 대상과 용도를 식별할 수 있게 정한다. 각 leaf의 구체적인 식별자는 해당 발급 실행 기록에 남긴다.

## 비밀 보관과 배포

- 개인 키와 passphrase는 Git, 이슈, 채팅, 문서 본문에 저장하지 않는다.
- 이 저장소의 `pki/.secrets/`, `*.key.pem`, `*.csr.pem`, `*.crt.pem`, `*.srl`은 `.gitignore`로 제외한다.
- Root CA 및 Intermediate CA 개인 키와 passphrase는 생성 직후 오프라인 비밀 저장소로 옮긴다. 이 작업 디렉터리는 운영 CA의 영구 저장소가 아니다.
- Issuing CA 개인 키는 leaf 발급이 끝난 뒤 통제된 CA 저장소로 옮긴다.
- Docker 호스트에는 해당 workload의 leaf 인증서와 개인 키만 읽기 전용으로 배치한다.

## AWS IAM Roles Anywhere 신뢰 규칙

현재 AWSRA Docker Compose는 leaf 인증서와 개인 키만 마운트하고 중간 인증서 전달 옵션을 사용하지 않는다. 따라서 후속 OpenTofu 작업은 `pki/awsra/issuing-ca.crt.pem`을 AWS Roles Anywhere trust anchor로 등록한다. Trust anchor, profile, role ARN과 leaf 개인 키 passphrase는 `.env` 또는 배포용 비밀 저장소를 통해 주입하며 Git에 저장하지 않는다.

## 발급, 기록, 폐기

- 인증서를 새로 만들거나 갱신하기 전에는 기존 대상 파일을 확인하고, 덮어쓰지 않는다.
- 발급 또는 갱신을 수행한 날마다 `pki/RUN-YYYY-mm-dd.md`에 수행 시각, 대상, subject, issuer, serial, SHA-256 fingerprint, 검증 결과와 후속 조치를 기록한다.
- 개인 키 유출, 잘못된 발급, workload 폐기 시에는 해당 leaf 사용을 중지하고 새 키와 인증서를 발급한다. AWS Roles Anywhere trust anchor 또는 profile 조건도 함께 검토한다.
- CA 개인 키 유출은 그 CA가 서명한 하위 인증서를 신뢰하지 않는 사고로 취급한다. 새 계층을 만들고 trust anchor를 교체하는 작업을 별도 실행 기록으로 남긴다.
