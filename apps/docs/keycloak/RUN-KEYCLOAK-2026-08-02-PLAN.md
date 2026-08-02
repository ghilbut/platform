---
type: run
area: apps
application: keycloak
cluster: cpa
status: planned
planned_at: 2026-08-02
completed_at:
---

# Keycloak Vault OIDC 실행 계획 — 2026-08-02

Vault 설치가 초기화와 auto-unseal 검증까지 완료된 뒤 실행한다. 관련 경로는 [Keycloak README](README.md)에서 확인한다. 이 문서는 [Applications Documents RULEBOOK](../RULEBOOK.md), [RUN-PLAN](../../../docs/obsidian/templates/RUN-PLAN.md) 템플릿과 [Documentation RULEBOOK RUNBOOK](../../../docs/RULEBOOK.md#runbook)을 따른다. Vault 쪽 설정과 root token 폐기는 [Vault 설치 실행 계획](../vault/RUN-VAULT-2026-08-02-PLAN.md#keycloak-oidc-운영자-인증과-root-token-폐기)에서 이어서 수행한다.

## 실행 값

| 항목 | 값 |
| --- | --- |
| Keycloak URL | `https://kc.ultary.co` |
| realm | `<KEYCLOAK_REALM>` |
| Vault OIDC client ID | `vault` |
| Vault 운영자 | `ghilbut` |
| Vault CLI redirect URI | `http://localhost:8250/oidc/callback` |

## Vault operator OIDC

1. Keycloak 관리 콘솔에서 `<KEYCLOAK_REALM>`을 선택한다. Vault 전용 realm이 없으면 기존 운영자 realm을 사용하기 전에 그 realm의 운영 정책을 확인한다.

2. 사용자를 만든다. username은 `ghilbut`로 설정하고 Enabled를 켠다. 비밀번호는 Git, 실행 계획, shell history에 기록하지 않고 승인된 비밀 보관소에서 생성·보관한다. 최초 로그인에서 비밀번호 변경을 요구할지 여부는 운영자 비밀번호 정책에 맞춘다.

3. OIDC client를 만든다. client ID는 `vault`이며 Client authentication은 켠다. Standard flow만 켜고 Direct access grants와 Service account roles는 끈다. Valid redirect URIs에는 다음 값만 추가한다.

   ```text
   http://localhost:8250/oidc/callback
   ```

4. client에 `profile` scope가 포함되어 ID token의 `preferred_username` claim이 `ghilbut`인지 확인한다. Vault는 이 claim으로 해당 사용자만 허용하므로 Keycloak realm role 또는 group을 Vault 권한 부여에 사용하지 않는다.

5. 생성된 client secret은 승인된 비밀 보관소에만 저장한다. 다음 값만 Vault 작업자에게 전달한다.

   - issuer URL: `https://kc.ultary.co/realms/<KEYCLOAK_REALM>`
   - client ID: `vault`
   - client secret의 보관 위치

## 결과

- 실행 일시:
- 실행자:
- realm:
- `ghilbut` 사용자 확인:
- Vault OIDC client와 redirect URI 확인:
- client secret 보관 위치 확인:
