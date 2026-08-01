# PKI 룰북

## 목적과 적용 범위

이 룰북은 사설 PKI의 CA와 leaf 인증서 전반에 적용한다. 생성·검증·배치 절차는 [RUNBOOK.md](RUNBOOK.md)를 따른다.

## 인증서 계층과 권한

```text
Root CA
  └── Intermediate CA
        └── Issuing CA
              └── Leaf 인증서
```

| 구성 요소 | 허용된 역할 | 개인 키 보관 |
| --- | --- | --- |
| Root CA | Intermediate CA 서명만 | 오프라인 보관 |
| Intermediate CA | Issuing CA 서명만 | 오프라인 보관 |
| Issuing CA | 승인된 leaf 서명만 | 접근이 통제된 CA 환경 |
| Leaf | 승인된 서비스 또는 workload의 인증만 | 해당 사용 주체 |

Leaf 인증서는 CA가 아니며 다른 인증서를 서명할 수 없다. 각 CA는 바로 아래 계층만 서명한다.

## 암호화와 이름 규칙

- 인증서 subject는 발급 목적과 소유 주체를 식별할 수 있어야 한다.
- 허용할 키 알고리즘, 서명 알고리즘, 유효 기간, key usage와 extended key usage는 발급 프로파일에서 정한다.
- CA에는 Basic Constraints와 `keyCertSign`, `cRLSign`을 설정한다. path length는 Root, Intermediate, Issuing 순서로 감소한다.
- Leaf에는 `CA:FALSE`를 설정하고, 용도에 맞는 key usage와 extended key usage만 부여한다.
- Issuing CA와 leaf의 파일 식별자는 소문자·숫자·하이픈만 사용하며, 동일한 식별자를 재사용하지 않는다.

## 비밀 보관과 신뢰 배포

- 개인 키와 passphrase는 Git, 이슈, 채팅, 문서 본문에 저장하지 않는다.
- 이 저장소의 `pki/.secrets/`, 개인 키, CSR, 인증서, serial 파일은 `.gitignore`로 제외한다.
- Root CA와 Intermediate CA 개인 키 및 passphrase는 생성 직후 오프라인 비밀 저장소로 옮긴다. 이 작업 디렉터리는 운영 CA의 영구 저장소가 아니다.
- Issuing CA 개인 키는 발급이 끝난 뒤 통제된 CA 저장소로 옮긴다.
- Leaf 인증서와 개인 키는 필요한 사용 주체에만 전달한다. 배포 경로, 파일 권한, 비밀 주입 방식은 서비스별 문서에서 정한다.
- 신뢰 주체에는 필요한 CA 인증서만 등록한다. 중간 인증서 전달 여부와 신뢰 anchor의 위치는 해당 서비스의 요구사항을 따른다.

## 발급, 기록, 폐기

- 인증서를 새로 만들거나 갱신하기 전에는 기존 대상 파일을 확인하고, 명시적인 교체 작업 없이 덮어쓰지 않는다.
- 개인 키 유출, 잘못된 발급, 사용 주체 폐기 시에는 해당 leaf 사용을 중지하고 새 키와 인증서를 발급한다. 신뢰 주체의 설정도 함께 검토한다.
- CA 개인 키 유출은 그 CA가 서명한 하위 인증서를 신뢰하지 않는 사고로 취급한다. 새 계층을 만들고 신뢰 주체를 교체하는 작업을 별도 실행 기록으로 남긴다.
