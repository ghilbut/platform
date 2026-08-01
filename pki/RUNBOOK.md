# PKI 런북

## 목적과 선행 조건

이 런북은 Root CA부터 AWS IAM Roles Anywhere leaf 인증서까지 한 체인을 생성·검증·배치하는 반복 절차다. 적용 원칙은 [RULEBOOK.md](RULEBOOK.md)를 따른다. 명령은 저장소 루트에서 `zsh`로 실행한다. 기존 인증서 또는 키가 있으면 해당 발급 기록을 확인하고, 명시적인 교체 작업 없이 덮어쓰지 않는다.

```shell
mkdir -p pki/awsra pki/.secrets
chmod 700 pki/.secrets
umask 077
```

## 1. Root CA 생성

```shell
test ! -e pki/root-ca.key.pem
test ! -e pki/root-ca.crt.pem
openssl rand -base64 -out pki/.secrets/root-ca.pass 48
chmod 600 pki/.secrets/root-ca.pass

openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-384 \
  -pkeyopt ec_param_enc:named_curve -aes-256-cbc \
  -pass file:pki/.secrets/root-ca.pass -out pki/root-ca.key.pem
chmod 400 pki/root-ca.key.pem

openssl req -x509 -new -sha384 -days 3650 \
  -key pki/root-ca.key.pem -passin file:pki/.secrets/root-ca.pass \
  -out pki/root-ca.crt.pem \
  -subj '/C=KR/O=Ghilbut/CN=Ghilbut Root CA' \
  -addext 'basicConstraints=critical,CA:TRUE,pathlen:2' \
  -addext 'keyUsage=critical,keyCertSign,cRLSign' \
  -addext 'subjectKeyIdentifier=hash'
chmod 444 pki/root-ca.crt.pem
```

## 2. Intermediate CA 생성

```shell
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
  -out pki/intermediate-ca.csr.pem \
  -subj '/C=KR/O=Ghilbut/CN=Ghilbut Intermediate CA'

openssl x509 -req -sha384 -days 3650 -in pki/intermediate-ca.csr.pem \
  -CA pki/root-ca.crt.pem -CAkey pki/root-ca.key.pem \
  -passin file:pki/.secrets/root-ca.pass -CAcreateserial \
  -CAserial pki/root-ca.srl -out pki/intermediate-ca.crt.pem \
  -extfile <(printf '%s\n' \
    'basicConstraints=critical,CA:TRUE,pathlen:1' \
    'keyUsage=critical,keyCertSign,cRLSign' \
    'subjectKeyIdentifier=hash' \
    'authorityKeyIdentifier=keyid:always,issuer')
chmod 444 pki/intermediate-ca.csr.pem pki/intermediate-ca.crt.pem
```

## 3. AWS Roles Anywhere Issuing CA 생성

```shell
test ! -e pki/awsra/issuing-ca.key.pem
test ! -e pki/awsra/issuing-ca.crt.pem
openssl rand -base64 -out pki/.secrets/awsra-issuing-ca.pass 48
chmod 600 pki/.secrets/awsra-issuing-ca.pass

openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-384 \
  -pkeyopt ec_param_enc:named_curve -aes-256-cbc \
  -pass file:pki/.secrets/awsra-issuing-ca.pass -out pki/awsra/issuing-ca.key.pem
chmod 400 pki/awsra/issuing-ca.key.pem

openssl req -new -sha384 -key pki/awsra/issuing-ca.key.pem \
  -passin file:pki/.secrets/awsra-issuing-ca.pass \
  -out pki/awsra/issuing-ca.csr.pem \
  -subj '/C=KR/O=Ghilbut/OU=Platform/OU=AWS Roles Anywhere/CN=Ghilbut AWS Roles Anywhere Issuing CA'

openssl x509 -req -sha384 -days 3650 -in pki/awsra/issuing-ca.csr.pem \
  -CA pki/intermediate-ca.crt.pem -CAkey pki/intermediate-ca.key.pem \
  -passin file:pki/.secrets/intermediate-ca.pass -CAcreateserial \
  -CAserial pki/intermediate-ca.srl -out pki/awsra/issuing-ca.crt.pem \
  -extfile <(printf '%s\n' \
    'basicConstraints=critical,CA:TRUE,pathlen:0' \
    'keyUsage=critical,keyCertSign,cRLSign' \
    'subjectKeyIdentifier=hash' \
    'authorityKeyIdentifier=keyid:always,issuer')
chmod 444 pki/awsra/issuing-ca.csr.pem pki/awsra/issuing-ca.crt.pem
```

## 4. AWS Roles Anywhere leaf 인증서 생성

```shell
test ! -e pki/awsra/synology-awsra.key.pem
test ! -e pki/awsra/synology-awsra.crt.pem
openssl rand -base64 -out pki/.secrets/synology-awsra.pass 48
chmod 600 pki/.secrets/synology-awsra.pass

openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-384 \
  -pkeyopt ec_param_enc:named_curve -aes-256-cbc \
  -pass file:pki/.secrets/synology-awsra.pass -out pki/awsra/synology-awsra.key.pem
chmod 400 pki/awsra/synology-awsra.key.pem

openssl req -new -sha384 -key pki/awsra/synology-awsra.key.pem \
  -passin file:pki/.secrets/synology-awsra.pass \
  -out pki/awsra/synology-awsra.csr.pem \
  -subj '/C=KR/O=Ghilbut/OU=Platform/OU=AWS Roles Anywhere/CN=awsra-for-ds1621plus'

openssl x509 -req -sha384 -days 3650 -in pki/awsra/synology-awsra.csr.pem \
  -CA pki/awsra/issuing-ca.crt.pem -CAkey pki/awsra/issuing-ca.key.pem \
  -passin file:pki/.secrets/awsra-issuing-ca.pass -CAcreateserial \
  -CAserial pki/awsra/issuing-ca.srl -out pki/awsra/synology-awsra.crt.pem \
  -extfile <(printf '%s\n' \
    'basicConstraints=critical,CA:FALSE' \
    'keyUsage=critical,digitalSignature' \
    'extendedKeyUsage=critical,clientAuth' \
    'subjectKeyIdentifier=hash' \
    'authorityKeyIdentifier=keyid:always,issuer')
chmod 444 pki/awsra/synology-awsra.csr.pem pki/awsra/synology-awsra.crt.pem
```

## 5. 검증과 배치

```shell
openssl verify -CAfile pki/root-ca.crt.pem pki/intermediate-ca.crt.pem
openssl verify -CAfile pki/root-ca.crt.pem \
  -untrusted pki/intermediate-ca.crt.pem pki/awsra/issuing-ca.crt.pem
openssl verify -purpose sslclient -CAfile pki/root-ca.crt.pem \
  -untrusted pki/intermediate-ca.crt.pem \
  -untrusted pki/awsra/issuing-ca.crt.pem pki/awsra/synology-awsra.crt.pem

CERT_PUBLIC_KEY_SHA256="$(openssl x509 -in pki/awsra/synology-awsra.crt.pem -pubkey -noout | openssl pkey -pubin -outform DER | openssl dgst -sha256)"
KEY_PUBLIC_KEY_SHA256="$(openssl pkey -in pki/awsra/synology-awsra.key.pem -passin file:pki/.secrets/synology-awsra.pass -pubout -outform DER | openssl dgst -sha256)"
test "$CERT_PUBLIC_KEY_SHA256" = "$KEY_PUBLIC_KEY_SHA256"
```

검증이 끝나면 Root CA와 Intermediate CA의 개인 키 및 passphrase를 오프라인 저장소로 옮긴다. 후속 OpenTofu 작업에서 `pki/awsra/issuing-ca.crt.pem`을 trust anchor로 등록한다. Docker Compose가 있는 `ultaryinc/ultary` 저장소에는 leaf 두 파일만 다음 위치에 배치한다.

```shell
install -d -m 700 "$ULTARY_REPO_ROOT/platform/core/docker/.pki"
install -m 0444 pki/awsra/synology-awsra.crt.pem \
  "$ULTARY_REPO_ROOT/platform/core/docker/.pki/synology-awsra.crt.pem"
install -m 0400 pki/awsra/synology-awsra.key.pem \
  "$ULTARY_REPO_ROOT/platform/core/docker/.pki/synology-awsra.key.pem"
```

배치 후에는 `RUN-YYYY-mm-dd.md`에 발급과 검증 결과를 기록한다. `.env` 생성과 OpenTofu 리소스 작성은 이 런북의 범위가 아니다.
