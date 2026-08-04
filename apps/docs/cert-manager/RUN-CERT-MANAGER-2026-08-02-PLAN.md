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
| IAM role | `domains-cpa-cert-manager` |
| DNS-01 ServiceAccount | `cert-manager/cert-manager` |
| Route 53 hosted zones | `ghilbut.com`, `ghilbut.net` |
| ClusterIssuer | `aws-route53` |
| Certificate | `istio-gateways/ingress-https` |
| TLS Secret | `istio-gateways/ingress-https-tls` |

## 실행 절차

1. Istio system과 gateway가 Healthy이고 `istio-gateways` namespace가 존재하는지 확인한다. Certificate의 TLS Secret은 이 namespace에 생성된다.

   ```sh
   kubectl --context cpa -n argo get application istio-system,istio-gateways
   kubectl --context cpa get namespace istio-gateways
   ```

2. Domains 계정에서 CPA cert-manager 전용 IAM 역할을 만든다. plan에는 CPA OIDC provider, `domains-cpa-cert-manager` 역할, `ghilbut.com`과 `ghilbut.net` Route 53 DNS-01 권한만 포함되어야 한다.

   ```sh
   AWS_PROFILE=ghilbut-tofu-apply-for-domains tofu -chdir=domains/tofu init
   AWS_PROFILE=ghilbut-tofu-apply-for-domains tofu -chdir=domains/tofu plan
   AWS_PROFILE=ghilbut-tofu-apply-for-domains tofu -chdir=domains/tofu apply
   ```

3. cert-manager Application을 동기화하고 chart와 `cert-manager` DNS-01 ServiceAccount RBAC가
   준비됐는지 확인한다. 이 단계는 AWS access key Secret을 만들거나 참조하지 않는다.

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
   kubectl --context cpa -n cert-manager get serviceaccount cert-manager
   kubectl --context cpa -n cert-manager auth can-i create serviceaccounts/token \
     --resource-name=cert-manager \
     --as=system:serviceaccount:cert-manager:cert-manager
   ```

4. Issuer와 Certificate 상태를 확인한다. DNS-01 challenge가 생성되면 `_acme-challenge` record는 cert-manager만 만들고 완료 뒤 제거한다.

   ```sh
   kubectl --context cpa get clusterissuer aws-route53
   kubectl --context cpa -n istio-gateways wait \
     --for=condition=Ready certificate/ingress-https \
     --timeout=20m
   kubectl --context cpa -n istio-gateways get secret ingress-https-tls
   kubectl --context cpa get order,challenge -A
   ```

5. Certificate가 Ready인 뒤 Istio Gateway가 참조하는 Secret 이름과 SAN을 확인한다. DNS record 공개와 Keycloak route는 후속 작업에서 실행한다.

   ```sh
   kubectl --context cpa -n istio-gateways get certificate ingress-https \
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
- `ingress-https-tls` Secret 확인:
- external-dns와 Keycloak 공개 route 작업 대기:
