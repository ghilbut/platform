---
type: run
area: apps
application: external-dns
cluster: cpa
status: planned
planned_at: 2026-08-03
paused_at:
paused_step:
paused_reason:
completed_at:
---

# external-dns 설치 실행 계획 — 2026-08-03

PR이 `main`에 병합된 뒤 실행한다. 관련 경로는 [external-dns README](README.md)에서 확인한다. 이 문서는 [Applications Documents RULEBOOK](../RULEBOOK.md), [RUN-PLAN](../../../docs/obsidian/templates/RUN-PLAN.md) 템플릿과 [Documentation RULEBOOK RUNBOOK](../../../docs/RULEBOOK.md#runbook)을 따른다.

## 실행 값

| 항목 | 값 |
| --- | --- |
| Kubernetes context | `cpa` |
| external-dns chart | `1.21.1` |
| IAM role | `platform-external-dns` |
| ServiceAccount | `external-dns/external-dns` |
| Gateway | `istio-gateways/public` |
| DNS target | `ghilbut.asuscomm.com` |
| Managed records | `id.ghilbut.com`, `vault.ghilbut.com` |
| TXT owner ID | `external-dns-cpa` |
| Deletion policy | `sync` |

## 실행 절차

1. Istio gateway가 Healthy이고 `public` Gateway의 host와 target annotation이 예상 값인지 확인한다.

   ```sh
   kubectl --context cpa -n argo get application istio-gateways
   kubectl --context cpa -n istio-gateways get gateway public \
     -o jsonpath='{.spec.servers[*].hosts}{"\n"}{.metadata.annotations.external-dns\.alpha\.kubernetes\.io/target}{"\n"}'
   dig +short ghilbut.asuscomm.com A
   ```

2. platform 계정에서 공용 external-dns IAM 역할을 만든다. plan에는 CPA OIDC provider 조회, `platform-external-dns` 역할과 선언한 Route 53 record 권한만 포함되어야 한다. 다른 cluster를 추가할 때는 해당 OIDC provider와 external-dns ServiceAccount subject를 trust에 추가하고, 서로 다른 `txtOwnerId`를 사용한다.

   ```sh
   tofu -chdir=apps/tofu init
   tofu -chdir=apps/tofu plan
   tofu -chdir=apps/tofu apply
   ```

3. external-dns Application을 동기화하고 Deployment와 ServiceAccount를 확인한다. 이 단계는 AWS access key Secret을 만들거나 참조하지 않는다.

   ```sh
   kubectl --context cpa -n argo patch application external-dns \
     --type=merge \
     --patch '{"operation":{"sync":{"prune":true}}}'
   kubectl --context cpa -n argo wait \
     --for=jsonpath='{.status.operationState.phase}'=Succeeded \
     application/external-dns \
     --timeout=15m
   kubectl --context cpa -n external-dns wait \
     --for=condition=Available deployment/external-dns \
     --timeout=10m
   kubectl --context cpa -n external-dns get serviceaccount external-dns
   ```

4. external-dns가 CNAME과 TXT ownership record를 만들었는지 확인한다. `sync`는 `public` Gateway에서 hostname을 제거할 때 같은 owner ID의 record와 TXT record만 삭제한다.

   ```sh
   kubectl --context cpa -n external-dns logs deployment/external-dns --tail=100
   dig +short id.ghilbut.com CNAME
   dig +short vault.ghilbut.com CNAME
   dig +short external-dns-id.ghilbut.com TXT
   dig +short external-dns-vault.ghilbut.com TXT
   ```

5. 두 hostname이 `ghilbut.asuscomm.com`을 가리키는지 확인하고 여기서 멈춘다. TLS Certificate와 Keycloak·Vault route 검증은 후속 이슈에서 실행한다.

   ```sh
   dig +short id.ghilbut.com A
   dig +short vault.ghilbut.com A
   ```

## 결과

- 실행 일시:
- 실행자:
- IAM 역할과 Route 53 권한 확인:
- external-dns Application과 ServiceAccount 확인:
- CNAME과 TXT ownership record 확인:
- Keycloak·Vault route 작업 대기:
