---
type: runbook
area: pki
---

# PKI 런북

## 목적

이 런북은 Root CA부터 leaf 인증서까지 체인을 생성하고 검증하는 공통 절차다. 적용 원칙은 [RULEBOOK.md](RULEBOOK.md)를 따른다. 명령은 POSIX 호환 `sh`에서 저장소 루트를 기준으로 실행한다. 기존 파일은 덮어쓰지 않는다.

발급 프로파일에 필요한 값은 각 절차의 시작에서 정한다. Issuing CA와 leaf의 식별자에는 소문자·숫자·하이픈만 사용한다.

## 1. Root CA 생성

```shell
ROOT_VALID_DAYS=3650
ROOT_SUBJECT='/C=KR/O=Example/CN=Example Root CA'

mkdir -p pki/.secrets
chmod 700 pki/.secrets
umask 077

test ! -e pki/root-ca.key.pem
test ! -e pki/root-ca.crt.pem
openssl rand -base64 -out pki/.secrets/root-ca.pass 48
chmod 600 pki/.secrets/root-ca.pass

openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-384 \
  -pkeyopt ec_param_enc:named_curve -aes-256-cbc \
  -pass file:pki/.secrets/root-ca.pass -out pki/root-ca.key.pem
chmod 400 pki/root-ca.key.pem

openssl req -x509 -new -sha384 -days "$ROOT_VALID_DAYS" \
  -key pki/root-ca.key.pem -passin file:pki/.secrets/root-ca.pass \
  -out pki/root-ca.crt.pem -subj "$ROOT_SUBJECT" \
  -addext 'basicConstraints=critical,CA:TRUE,pathlen:2' \
  -addext 'keyUsage=critical,keyCertSign,cRLSign' \
  -addext 'subjectKeyIdentifier=hash'
chmod 444 pki/root-ca.crt.pem

openssl verify -CAfile pki/root-ca.crt.pem pki/root-ca.crt.pem
openssl x509 -in pki/root-ca.crt.pem -noout -subject -issuer -serial -dates
```

## 2. Intermediate CA 생성

```shell
INTERMEDIATE_VALID_DAYS=3650
INTERMEDIATE_SUBJECT='/C=KR/O=Example/CN=Example Intermediate CA'
EXT_DIR='pki/.tmp'

mkdir -p pki/.secrets "$EXT_DIR"
chmod 700 pki/.secrets
umask 077

test ! -e pki/intermediate-ca.key.pem
test ! -e pki/intermediate-ca.crt.pem
openssl rand -base64 -out pki/.secrets/intermediate-ca.pass 48
chmod 600 pki/.secrets/intermediate-ca.pass

openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-384 \
  -pkeyopt ec_param_enc:named_curve -aes-256-cbc \
  -pass file:pki/.secrets/intermediate-ca.pass -out pki/intermediate-ca.key.pem
chmod 400 pki/intermediate-ca.key.pem

openssl req -new -sha384 -key pki/intermediate-ca.key.pem \
  -passin file:pki/.secrets/intermediate-ca.pass \
  -out pki/intermediate-ca.csr.pem -subj "$INTERMEDIATE_SUBJECT"

INTERMEDIATE_EXT="$EXT_DIR/intermediate-ca.ext"
printf '%s\n' \
  'basicConstraints=critical,CA:TRUE,pathlen:1' \
  'keyUsage=critical,keyCertSign,cRLSign' \
  'subjectKeyIdentifier=hash' \
  'authorityKeyIdentifier=keyid:always,issuer' > "$INTERMEDIATE_EXT"

openssl x509 -req -sha384 -days "$INTERMEDIATE_VALID_DAYS" -in pki/intermediate-ca.csr.pem \
  -CA pki/root-ca.crt.pem -CAkey pki/root-ca.key.pem \
  -passin file:pki/.secrets/root-ca.pass -CAcreateserial \
  -CAserial pki/root-ca.srl -out pki/intermediate-ca.crt.pem \
  -extfile "$INTERMEDIATE_EXT"
rm -f "$INTERMEDIATE_EXT"
chmod 444 pki/intermediate-ca.csr.pem pki/intermediate-ca.crt.pem

openssl verify -CAfile pki/root-ca.crt.pem pki/intermediate-ca.crt.pem
openssl x509 -in pki/intermediate-ca.crt.pem -noout -subject -issuer -serial -dates
```

## 3. Issuing CA 생성

```shell
ISSUING_CA_VALID_DAYS=3650
ISSUING_CA_ID='service-issuing-ca'
ISSUING_CA_SUBJECT='/C=KR/O=Example/OU=Platform/CN=Example Service Issuing CA'
APPLICATION_PKI_DIR='apps/example/pki'
ISSUING_CA_DIR="$APPLICATION_PKI_DIR/issuers/$ISSUING_CA_ID"
SECRET_DIR="$APPLICATION_PKI_DIR/.secrets"
EXT_DIR='pki/.tmp'

mkdir -p "$ISSUING_CA_DIR" "$SECRET_DIR" "$EXT_DIR"
chmod 700 "$SECRET_DIR"
umask 077

test ! -e "$ISSUING_CA_DIR/ca.key.pem"
test ! -e "$ISSUING_CA_DIR/ca.crt.pem"
openssl rand -base64 -out "$SECRET_DIR/$ISSUING_CA_ID.pass" 48
chmod 600 "$SECRET_DIR/$ISSUING_CA_ID.pass"

openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-384 \
  -pkeyopt ec_param_enc:named_curve -aes-256-cbc \
  -pass "file:$SECRET_DIR/$ISSUING_CA_ID.pass" -out "$ISSUING_CA_DIR/ca.key.pem"
chmod 400 "$ISSUING_CA_DIR/ca.key.pem"

openssl req -new -sha384 -key "$ISSUING_CA_DIR/ca.key.pem" \
  -passin "file:$SECRET_DIR/$ISSUING_CA_ID.pass" \
  -out "$ISSUING_CA_DIR/ca.csr.pem" -subj "$ISSUING_CA_SUBJECT"

ISSUING_CA_EXT="$EXT_DIR/$ISSUING_CA_ID.ext"
printf '%s\n' \
  'basicConstraints=critical,CA:TRUE,pathlen:0' \
  'keyUsage=critical,keyCertSign,cRLSign' \
  'subjectKeyIdentifier=hash' \
  'authorityKeyIdentifier=keyid:always,issuer' > "$ISSUING_CA_EXT"

openssl x509 -req -sha384 -days "$ISSUING_CA_VALID_DAYS" -in "$ISSUING_CA_DIR/ca.csr.pem" \
  -CA pki/intermediate-ca.crt.pem -CAkey pki/intermediate-ca.key.pem \
  -passin file:pki/.secrets/intermediate-ca.pass -CAcreateserial \
  -CAserial pki/intermediate-ca.srl -out "$ISSUING_CA_DIR/ca.crt.pem" \
  -extfile "$ISSUING_CA_EXT"
rm -f "$ISSUING_CA_EXT"
chmod 444 "$ISSUING_CA_DIR/ca.csr.pem" "$ISSUING_CA_DIR/ca.crt.pem"

openssl verify -CAfile pki/root-ca.crt.pem \
  -untrusted pki/intermediate-ca.crt.pem "$ISSUING_CA_DIR/ca.crt.pem"
openssl x509 -in "$ISSUING_CA_DIR/ca.crt.pem" -noout -subject -issuer -serial -dates
```

## 4. Leaf 인증서 생성

```shell
LEAF_VALID_DAYS=3650
ISSUING_CA_ID='service-issuing-ca'
LEAF_ID='service-workload'
LEAF_SUBJECT='/C=KR/O=Example/OU=Platform/CN=service-workload'
LEAF_KEY_USAGE='digitalSignature'
LEAF_EXTENDED_KEY_USAGE='clientAuth'
APPLICATION_PKI_DIR='apps/example/pki'
ISSUING_CA_DIR="$APPLICATION_PKI_DIR/issuers/$ISSUING_CA_ID"
LEAF_DIR="$APPLICATION_PKI_DIR/leaves/$LEAF_ID"
SECRET_DIR="$APPLICATION_PKI_DIR/.secrets"
EXT_DIR='pki/.tmp'

mkdir -p "$LEAF_DIR" "$SECRET_DIR" "$EXT_DIR"
chmod 700 "$SECRET_DIR"
umask 077

test ! -e "$LEAF_DIR/$LEAF_ID.key.pem"
test ! -e "$LEAF_DIR/$LEAF_ID.crt.pem"
openssl rand -base64 -out "$SECRET_DIR/$LEAF_ID.pass" 48
chmod 600 "$SECRET_DIR/$LEAF_ID.pass"

openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-384 \
  -pkeyopt ec_param_enc:named_curve -aes-256-cbc \
  -pass "file:$SECRET_DIR/$LEAF_ID.pass" -out "$LEAF_DIR/$LEAF_ID.key.pem"
chmod 400 "$LEAF_DIR/$LEAF_ID.key.pem"

openssl req -new -sha384 -key "$LEAF_DIR/$LEAF_ID.key.pem" \
  -passin "file:$SECRET_DIR/$LEAF_ID.pass" \
  -out "$LEAF_DIR/$LEAF_ID.csr.pem" -subj "$LEAF_SUBJECT"

LEAF_EXT="$EXT_DIR/$LEAF_ID.ext"
printf '%s\n' \
  'basicConstraints=critical,CA:FALSE' \
  "keyUsage=critical,$LEAF_KEY_USAGE" \
  "extendedKeyUsage=critical,$LEAF_EXTENDED_KEY_USAGE" \
  'subjectKeyIdentifier=hash' \
  'authorityKeyIdentifier=keyid:always,issuer' > "$LEAF_EXT"

openssl x509 -req -sha384 -days "$LEAF_VALID_DAYS" -in "$LEAF_DIR/$LEAF_ID.csr.pem" \
  -CA "$ISSUING_CA_DIR/ca.crt.pem" -CAkey "$ISSUING_CA_DIR/ca.key.pem" \
  -passin "file:$SECRET_DIR/$ISSUING_CA_ID.pass" -CAcreateserial \
  -CAserial "$ISSUING_CA_DIR/ca.srl" -out "$LEAF_DIR/$LEAF_ID.crt.pem" \
  -extfile "$LEAF_EXT"
rm -f "$LEAF_EXT"
chmod 444 "$LEAF_DIR/$LEAF_ID.csr.pem" "$LEAF_DIR/$LEAF_ID.crt.pem"

openssl verify -CAfile pki/root-ca.crt.pem \
  -untrusted pki/intermediate-ca.crt.pem \
  -untrusted "$ISSUING_CA_DIR/ca.crt.pem" "$LEAF_DIR/$LEAF_ID.crt.pem"

CERT_PUBLIC_KEY_SHA256="$(openssl x509 -in "$LEAF_DIR/$LEAF_ID.crt.pem" -pubkey -noout | openssl pkey -pubin -outform DER | openssl dgst -sha256)"
KEY_PUBLIC_KEY_SHA256="$(openssl pkey -in "$LEAF_DIR/$LEAF_ID.key.pem" -passin "file:$SECRET_DIR/$LEAF_ID.pass" -pubout -outform DER | openssl dgst -sha256)"
test "$CERT_PUBLIC_KEY_SHA256" = "$KEY_PUBLIC_KEY_SHA256"
openssl x509 -in "$LEAF_DIR/$LEAF_ID.crt.pem" -noout -subject -issuer -serial -dates
```

검증이 끝나면 Root CA와 Intermediate CA의 개인 키 및 passphrase를 오프라인 저장소로 옮긴다. 발급한 인증서의 배포와 신뢰 설정은 서비스별 문서를 따른다.

## 5. 실행 기록

이 런북을 실제로 수행한 날마다 해당 CA 또는 application PKI 디렉터리에 `RUN-YYYY-mm-dd.md`를 만든다. 기록에는 수행 시각, 발급 대상, subject, issuer, serial, SHA-256 fingerprint, 체인·키 일치 검증 결과, 배포 여부와 후속 조치를 포함한다. 개인 키와 passphrase는 기록하지 않는다.
