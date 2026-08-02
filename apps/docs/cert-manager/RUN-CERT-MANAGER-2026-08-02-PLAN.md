---
type: run
area: apps
application: cert-manager
cluster: cpa
status: planned
planned_at: 2026-08-02
paused_at:
paused_step:
paused_reason:
completed_at:
---

# cert-manager 설치 실행 계획 — 2026-08-02

PR이 `main`에 병합된 뒤 실행한다. 관련 경로는 [cert-manager README](README.md)에서 확인한다. 이 문서는 [Applications Documents RULEBOOK](../RULEBOOK.md), [RUN-PLAN](../../../docs/obsidian/templates/RUN-PLAN.md) 템플릿과 [Documentation RULEBOOK RUNBOOK](../../../docs/RULEBOOK.md#runbook)을 따른다.

## 실행 값

| 항목 | 값 |
| --- | --- |
| Kubernetes context | `cpa` |
| cert-manager version | `v1.21.1` |
| IAM role | `platform-cert-manager` |
| DNS-01 ServiceAccount | `istio-gateways/cert-manager-dns01` |
| Route 53 hosted zones | `ghilbut.com`, `ghilbut.net` |
| Issuer | `istio-gateways/aws-route53` |
| Certificate | `istio-gateways/public-https` |
| TLS Secret | `istio-gateways/public-https-tls` |

## 실행 절차

1. Istio system과 gateway가 Healthy이고 `istio-gateways` namespace가 존재하는지 확인한다. Certificate의 TLS Secret은 이 namespace에 생성된다.

   ```sh
   kubectl --context cpa -n argo get application istio-system,istio-gateways
   kubectl --context cpa get namespace istio-gateways
   ```

2. platform 계정에서 공용 cert-manager IAM 역할을 만든다. plan에는 CPA OIDC provider 조회, `platform-cert-manager` 역할, `ghilbut.com`과 `ghilbut.net` Route 53 DNS-01 권한만 포함되어야 한다. 다른 cluster를 추가할 때는 해당 OIDC provider와 DNS-01 ServiceAccount subject를 trust에 추가한다.

   ```sh
   tofu -chdir=apps/tofu init
   tofu -chdir=apps/tofu plan
   tofu -chdir=apps/tofu apply
   ```

3. cert-manager Application을 동기화하고 chart와 `istio-gateways` DNS-01 ServiceAccount RBAC가 준비됐는지 확인한다. 이 단계는 AWS access key Secret을 만들거나 참조하지 않는다.

   ```sh
   kubectl --context cpa -n argo patch application cert-manager \
     --type=merge \
     --patch '{"operation":{"sync":{"prune":true}}}'
   kubectl --context cpa -n argo wait \
     --for=jsonpath='{.status.operationState.phase}'=Succeeded \
     application/cert-manager \
     --timeout=15m
   kubectl --context cpa -n cert-manager wait \
     --for=condition=Available deployment/cert-manager \
     --timeout=10m
   kubectl --context cpa -n istio-gateways get serviceaccount cert-manager-dns01
   kubectl --context cpa -n istio-gateways auth can-i create serviceaccounts/token \
     --resource-name=cert-manager-dns01 \
     --as=system:serviceaccount:cert-manager:cert-manager
   ```

4. Issuer와 Certificate 상태를 확인한다. DNS-01 challenge가 생성되면 `_acme-challenge` record는 cert-manager만 만들고 완료 뒤 제거한다.

   ```sh
   kubectl --context cpa -n istio-gateways get issuer aws-route53
   kubectl --context cpa -n istio-gateways wait \
     --for=condition=Ready certificate/public-https \
     --timeout=20m
   kubectl --context cpa -n istio-gateways get secret public-https-tls
   kubectl --context cpa get order,challenge -A
   ```

5. Certificate가 Ready인 뒤 Istio Gateway가 참조하는 Secret 이름과 SAN을 확인한다. DNS record 공개와 Keycloak·Vault route는 후속 이슈에서 실행한다.

   ```sh
   kubectl --context cpa -n istio-gateways get certificate public-https \
     -o jsonpath='{.spec.dnsNames}{"\n"}'
   kubectl --context cpa -n istio-gateways get gateway public \
     -o jsonpath='{.spec.servers[1].tls.credentialName}{"\n"}'
   ```

## 결과

- 실행 일시:
- 실행자:
- IAM 역할과 Route 53 권한 확인:
- cert-manager Application과 DNS-01 ServiceAccount RBAC 확인:
- Issuer와 Certificate Ready 확인:
- `public-https-tls` Secret 확인:
- external-dns, Keycloak, Vault 공개 route 작업 대기:
