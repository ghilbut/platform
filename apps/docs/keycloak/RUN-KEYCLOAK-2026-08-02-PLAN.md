---
type: run
area: apps
application: keycloak
cluster: cpa
status: planned
planned_at: 2026-08-02
paused_at:
paused_step:
paused_reason:
completed_at:
---

# Keycloak Vault OIDC 실행 계획 — 2026-08-02

Vault 설치가 초기화와 auto-unseal 검증까지 완료된 뒤 실행한다. 관련 경로는 [Keycloak README](README.md)에서 확인한다. 이 문서는 [Applications Documents RULEBOOK](../RULEBOOK.md), [RUN-PLAN](../../../docs/obsidian/templates/RUN-PLAN.md) 템플릿과 [Documentation RULEBOOK RUNBOOK](../../../docs/RULEBOOK.md#runbook)을 따른다. Vault 쪽 설정과 root token 폐기는 [Vault 설치 실행 계획](../vault/RUN-VAULT-2026-08-02-PLAN.md#keycloak-oidc-운영자-인증과-root-token-폐기)에서 이어서 수행한다.

## 실행 값

| 항목 | 값 |
| --- | --- |
| Keycloak URL | `https://kc.ultary.co` |
| Vault OIDC realm | `ghilbut` |
| Vault OIDC client ID | `vault` |
| Vault 운영자 | `ghilbut` |
| Vault CLI redirect URI | `http://localhost:8250/oidc/callback` |

## Vault operator OIDC

Keycloak 조작은 관리 콘솔이 아니라 Keycloak과 같은 버전의 `kcadm.sh`로 수행한다. 실행자는 `master` realm에서 realm을 만들 수 있고 `ghilbut` realm을 관리할 수 있는 관리자 계정을 사용한다. `kcadm.sh`가 설치된 관리자 컴퓨터에서 다음 shell function을 준비한다. `--no-config`는 인증 token을 로컬 파일에 저장하지 않는다.

```sh
read -r KEYCLOAK_ADMIN_USER
read -rs KEYCLOAK_ADMIN_PASSWORD
printf '\n'

kc_admin() {
  kcadm.sh "$@" \
    --no-config \
    --server 'https://kc.ultary.co' \
    --realm 'master' \
    --user "$KEYCLOAK_ADMIN_USER" \
    --password "$KEYCLOAK_ADMIN_PASSWORD"
}
```

1. realm `ghilbut`을 조회한다. 존재하지 않는다는 응답일 때만 다음 생성 명령을 실행한다. 인증 오류나 연결 오류에는 생성 명령을 실행하지 않는다. 이미 있으면 enabled 상태만 확인하고 기존 설정을 덮어쓰지 않는다.

   ```sh
   kc_admin get realms/ghilbut
   ```

   ```sh
   kc_admin create realms -s realm='ghilbut' -s enabled=true
   ```

2. `ghilbut` 사용자를 조회한다. 조회 결과가 비어 있을 때만 사용자를 만들고, 승인된 비밀 보관소에서 읽은 초기 비밀번호를 설정한다. `--temporary`를 사용하므로 최초 Keycloak 로그인에서 사용자가 비밀번호를 바꾼다.

   ```sh
   kc_admin get users -r ghilbut -q username=ghilbut -q exact=true --fields id,username
   ```

   조회 결과가 `[]`일 때만 다음 명령을 실행한다.

   ```sh
   kc_admin create users -r ghilbut -s username='ghilbut' -s enabled=true

   read -rs KEYCLOAK_GHILBUT_PASSWORD
   printf '\n'
   kc_admin set-password \
     -r ghilbut \
     --username ghilbut \
     --new-password "$KEYCLOAK_GHILBUT_PASSWORD" \
     --temporary
   unset KEYCLOAK_GHILBUT_PASSWORD
   ```

   기존 username이 있으면 생성 명령을 다시 실행하지 않는다. 기존 사용자의 비밀번호 변경은 별도 변경으로 취급한다.

3. `vault` OIDC client를 만든다. client authentication과 authorization code flow만 켜고, Direct access grants와 service account는 끈다. 기존 client가 없을 때만 생성한다.

   ```text
   http://localhost:8250/oidc/callback
   ```

   ```sh
   kc_admin get clients -r ghilbut -q clientId=vault --fields id,clientId
   ```

   조회 결과가 `[]`일 때만 다음 명령을 실행한다.

   ```sh
   kc_admin create clients \
     -r ghilbut \
     -s clientId='vault' \
     -s enabled=true \
     -s publicClient=false \
     -s clientAuthenticatorType='client-secret' \
     -s standardFlowEnabled=true \
     -s directAccessGrantsEnabled=false \
     -s serviceAccountsEnabled=false \
     -s 'redirectUris=["http://localhost:8250/oidc/callback"]' \
     -s 'webOrigins=["http://localhost:8250"]'
   ```

   생성했거나 기존 client를 사용하기로 확인했으면 다시 조회해 `id`를 `<VAULT_CLIENT_UUID>`로 기록한다.

   ```sh
   kc_admin get clients -r ghilbut -q clientId=vault --fields id,clientId
   ```

4. `vault` client의 `id`를 `<VAULT_CLIENT_UUID>`에 넣어 client secret과 default client scope를 확인한다. 출력된 secret은 즉시 승인된 비밀 보관소에만 저장한다. `profile` scope가 있어 ID token의 `preferred_username` claim이 `ghilbut`인지 확인한다.

   ```sh
   export VAULT_CLIENT_UUID='<VAULT_CLIENT_UUID>'
   kc_admin get clients/"$VAULT_CLIENT_UUID"/client-secret -r ghilbut
   kc_admin get clients/"$VAULT_CLIENT_UUID"/default-client-scopes -r ghilbut --fields name
   unset VAULT_CLIENT_UUID
   ```

   Vault는 `preferred_username=ghilbut`만 허용하므로 Keycloak realm role 또는 group을 Vault 권한 부여에 사용하지 않는다.

5. Vault 작업자에게 다음 값과 client secret의 비밀 보관소 위치를 전달한다. 관리자 credential은 지운다.

   - issuer URL: `https://kc.ultary.co/realms/ghilbut`
   - client ID: `vault`
   - client secret의 보관 위치

   ```sh
   unset KEYCLOAK_ADMIN_PASSWORD
   unset KEYCLOAK_ADMIN_USER
   unset -f kc_admin
   ```

## 결과

- 실행 일시:
- 실행자:
- realm: `ghilbut`
- `ghilbut` 사용자 확인:
- Vault OIDC client와 redirect URI 확인:
- client secret 보관 위치 확인:
