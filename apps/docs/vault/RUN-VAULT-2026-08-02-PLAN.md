---
type: run
area: apps
application: vault
cluster: cpa
status: paused
planned_at: 2026-08-02
paused_at: 2026-08-02
paused_step: "7단계: Keycloak Vault operator OIDC"
paused_reason: "Vault 수동 초기화와 AWS KMS auto-unseal 검증을 완료했다. Keycloak master realm 관리자 자격 증명과 Vault root token을 채팅이나 자동화에 노출하지 않기 위해 지정된 운영자가 CLI 절차를 수행해야 한다."
completed_at:
---

# Vault 설치 실행 계획 — 2026-08-02

PR이 `main`에 병합된 뒤 실행한다. 이 문서는 [RUN-PLAN](../../../docs/obsidian/templates/RUN-PLAN.md) 템플릿과 [Documentation RULEBOOK RUNBOOK](../../../docs/RULEBOOK.md#runbook)을 따른다. 일반적인 5개 생성·3개 필요 대신, 단일 운영자의 소규모 환경에 맞춰 recovery key 3개 생성·2개 필요 구성을 사용한다. 반복 운영은 [Vault 운영 RUNBOOK](RUNBOOK.md), 복구와 이전은 [Vault 복구 PLAYBOOK](PLAYBOOK.md)을 따른다.

## 실행 값

| 항목 | 값 |
| --- | --- |
| AWS profile | `ghilbut-platform` |
| Kubernetes context | `cpa` |
| Argo CD Application | `vault` |
| Vault Pod | `vault-0` |

## 실행 절차

1. repository root에서 AWS 계정과 Kubernetes context를 확인한다.

   ```sh
   aws sts get-caller-identity --profile ghilbut-platform
   kubectl --context cpa get nodes
   ```

2. CPA IAM OIDC provider를 적용한다. plan에 CPA OIDC provider와 공개 OIDC object만 포함되는지 확인한 뒤 apply한다.

   ```sh
   cd k3s/tofu
   tofu init
   tofu plan
   tofu apply
   ```

3. Vault AWS KMS seal key와 IAM 역할을 적용한다. plan에서 `platform-vault` 역할, 역할 정책, KMS key와 alias를 확인한 뒤 apply한다.

   ```sh
   cd ../../apps/tofu
   tofu init
   tofu plan
   tofu apply
   ```

4. Vault Application을 등록하고 동기화한다. `data-vault-0` PVC가 `Bound`가 된 뒤 Pod가 준비될 때까지 기다린다.

   ```sh
   cd ../..
   kubectl --context cpa -n argo apply -f apps/argo-apps/vault.yaml
   argocd app sync vault
   kubectl --context cpa -n vault get serviceaccount,pvc,pod
   kubectl --context cpa -n vault wait --for=jsonpath='{.status.phase}'=Running pod/vault-0 --timeout=10m
   kubectl --context cpa -n vault exec vault-0 -- vault status
   ```

5. `Seal Type: awskms`와 `Initialized: false`를 확인한 뒤 Vault를 한 번만 초기화한다. 출력의 root token과 recovery key는 즉시 수령해 승인된 별도 보관소로 전달한다.

   ```sh
   kubectl --context cpa -n vault exec -it vault-0 -- \
     vault operator init \
     -recovery-shares=3 \
     -recovery-threshold=2 \
     -format=json
   kubectl --context cpa -n vault exec vault-0 -- vault status
   ```

6. Pod를 재생성해 AWS KMS auto-unseal을 검증한다. `Initialized: true`와 `Sealed: false`를 확인한다.

   ```sh
   kubectl --context cpa -n vault delete pod vault-0
   kubectl --context cpa -n vault wait --for=condition=Ready pod/vault-0 --timeout=10m
   kubectl --context cpa -n vault exec vault-0 -- vault status
   ```

7. [Keycloak Vault operator OIDC](../keycloak/RUN-KEYCLOAK-2026-08-02-PLAN.md#vault-operator-oidc)를 완료한다. Keycloak 작업에서 정한 issuer URL과 client secret을 사용해 Vault OIDC auth method와 `ghilbut` 운영자 identity를 설정한다. 이 identity는 Keycloak이 인증한 사람과 Vault policy를 연결한 주체이며, root token이나 Kubernetes ServiceAccount가 아니다.

   첫 터미널에서 Vault API를 관리자 컴퓨터의 loopback에만 연결한다.

   ```sh
   kubectl --context cpa -n vault port-forward pod/vault-0 8200:8200
   ```

   둘째 터미널에서 root token을 화면에 표시하지 않고 입력한다. OIDC issuer는 Keycloak `ghilbut` realm이다. client secret도 비밀 보관소에서 직접 입력한다.

   ```sh
   export VAULT_ADDR='http://127.0.0.1:8200'
   read -rs VAULT_TOKEN
   export VAULT_TOKEN
   vault auth enable -path=oidc oidc

   vault policy write vault-operator - <<'EOF'
   path "sys/health" {
     capabilities = ["read"]
   }

   path "sys/seal-status" {
     capabilities = ["read"]
   }

   path "sys/leader" {
     capabilities = ["read"]
   }

   path "sys/storage/raft/snapshot" {
     capabilities = ["read"]
   }

   path "sys/generate-root/*" {
     capabilities = ["update"]
   }

   path "sys/rekey/*" {
     capabilities = ["update"]
   }
   EOF

   read -rs KEYCLOAK_CLIENT_SECRET
   export KEYCLOAK_CLIENT_SECRET
   vault write auth/oidc/config \
     oidc_discovery_url='https://kc.ultary.co/realms/ghilbut' \
     oidc_client_id='vault' \
     oidc_client_secret="$KEYCLOAK_CLIENT_SECRET" \
     default_role='vault-operator'
   vault write auth/oidc/role/vault-operator - <<'EOF'
   {
     "role_type": "oidc",
     "user_claim": "preferred_username",
     "bound_audiences": ["vault"],
     "bound_claims": {
       "preferred_username": "ghilbut"
     },
     "allowed_redirect_uris": [
       "http://localhost:8250/oidc/callback"
     ],
     "oidc_scopes": ["openid", "profile", "email"],
     "policies": ["vault-operator"]
   }
   EOF
   unset KEYCLOAK_CLIENT_SECRET
   unset VAULT_TOKEN
   ```

8. `ghilbut`로 Keycloak 로그인을 완료하고 Vault policy가 적용되는지 확인한다. browser가 열리면 Keycloak에서 `ghilbut` 사용자로 로그인한다. 이 확인이 성공하기 전에는 root token을 폐기하지 않는다.

   ```sh
   vault login -method=oidc -path=oidc role=vault-operator
   vault token lookup
   vault token capabilities sys/storage/raft/snapshot
   ```

9. OIDC token으로 8단계의 확인이 성공한 뒤에만 root token을 Vault 내부에서 폐기한다. root token을 보관한 별도 터미널에서 실행한다. 이 명령은 Vault 서버가 해당 token을 revoke하여 더 이상 인증에 사용할 수 없게 한다.

   ```sh
   export VAULT_ADDR='http://127.0.0.1:8200'
   read -rs VAULT_TOKEN
   export VAULT_TOKEN
   vault token revoke -self
   unset VAULT_TOKEN
   ```

   revoke가 성공하면 외부의 root token 사본도 제거한다. 초기화 JSON 출력 파일, 붙여넣기한 clipboard, 메모와 비밀 보관소의 root token 항목을 삭제하고, token을 표시한 터미널 세션을 종료하거나 scrollback을 지운다. recovery key 3개는 삭제하지 않고 서로 다른 보관 위치에 유지한다. 실행 결과에는 token 값이나 client secret을 기록하지 않는다.

10. root token 폐기 뒤에도 새 OIDC 로그인이 가능하고 snapshot 권한이 유지되는지 다시 확인한다. 첫 snapshot은 [Vault 운영 RUNBOOK](RUNBOOK.md#수동-raft-snapshot)에 따라 별도 수행한다.

    ```sh
    vault login -method=oidc -path=oidc role=vault-operator
    vault token capabilities sys/storage/raft/snapshot
    ```

## 결과

- 실행 일시: 2026-08-02
- 실행자: `ghilbut-platform` AWS role session으로 보조 실행
- K3s OpenTofu 결과: CPA IAM OIDC provider 1개 생성
- Applications OpenTofu 결과: Vault KMS key·alias, `platform-vault` IAM role·KMS policy 4개 생성
- Argo CD 동기화 결과: `data-vault-0` PVC와 PV가 10 GiB로 Bound됐고 `vault-0`은 AWS KMS seal로 실행 중
- 초기화·비밀 수령·auto-unseal 검증 확인: 수동 초기화 후 Pod를 재생성했다. 재생성된 `vault-0`에서 `Seal Type: awskms`, `Initialized: true`, `Sealed: false`, `HA Mode: active`를 확인했다.
- Keycloak OIDC 로그인과 `vault-operator` policy 확인:
- Vault 내부 root token revoke와 외부 사본 제거 확인:
- 중단 이력: 4단계에서 `data-vault-0` PVC가 `WaitForFirstConsumer`로 `Pending` 상태였다. namespace와 ServiceAccount는 생성됐고, StatefulSet은 생성되지 않았다.
- 중단 이력: `openebs-lvm`을 `Immediate`로 재생성한 뒤 PVC와 PV는 Bound됐으나, `automountServiceAccountToken: false` 때문에 Vault HA Kubernetes service registration이 기본 ServiceAccount token을 찾지 못해 Pod가 시작하지 못했다.
- 현재 중단: 5·6단계를 완료했다. `kcadm.sh`는 관리자 환경에 있으며, 지정된 운영자가 Keycloak `master` realm 관리자 자격 증명을 사용해 7단계의 Keycloak CLI 절차를 수행할 때까지 멈춘다. client secret은 승인된 별도 보관소에만 저장한다.
