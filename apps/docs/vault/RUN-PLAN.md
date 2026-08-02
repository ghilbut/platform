---
type: run
area: apps
application: vault
cluster: cpa
status: planned
planned_at: 2026-08-02
completed_at:
---

# Vault 설치 RUN-PLAN

PR이 `main`에 병합된 뒤 실행한다. 반복 운영은 [Vault 운영 RUNBOOK](RUNBOOK.md), 복구와 이전은 [Vault 복구 PLAYBOOK](PLAYBOOK.md)을 따른다.

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
   kubectl --context cpa -n vault rollout status statefulset/vault --timeout=10m
   kubectl --context cpa -n vault exec vault-0 -- vault status
   ```

5. `Seal Type: awskms`와 `Initialized: false`를 확인한 뒤 Vault를 한 번만 초기화한다. 출력의 root token과 recovery key는 즉시 수령해 승인된 별도 보관소로 전달한다.

   ```sh
   kubectl --context cpa -n vault exec -it vault-0 -- \
     vault operator init \
     -recovery-shares=5 \
     -recovery-threshold=3 \
     -format=json
   kubectl --context cpa -n vault exec vault-0 -- vault status
   ```

6. `Initialized: true`와 `Sealed: false`를 확인한다. 운영자 identity를 만든 뒤 root token을 폐기하고, 첫 snapshot과 auto-unseal 재시작 검증은 RUNBOOK에 따라 별도 수행한다.

## 결과

- 실행 일시:
- 실행자:
- K3s OpenTofu 결과:
- Applications OpenTofu 결과:
- Argo CD 동기화 결과:
- 초기화와 비밀 수령 확인:
