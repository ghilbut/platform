---
type: run
area: apps
application: istio
cluster: cpa
status: planned
planned_at: 2026-08-02
paused_at:
paused_step:
paused_reason:
completed_at:
---

# Istio 설치 실행 계획 — 2026-08-02

PR이 `main`에 병합된 뒤 실행한다. 관련 경로는 [Istio README](README.md)에서 확인한다. 이 문서는 [Applications Documents RULEBOOK](../RULEBOOK.md), [RUN-PLAN](../../../docs/obsidian/templates/RUN-PLAN.md) 템플릿과 [Documentation RULEBOOK RUNBOOK](../../../docs/RULEBOOK.md#runbook)을 따른다.

## 실행 값

| 항목 | 값 |
| --- | --- |
| Kubernetes context | `cpa` |
| Istio version | `1.30.3` |
| Argo CD Applications | `cilium`, `istio-system`, `istio-gateways` |
| Ingress Service | `istio-ingressgateway` |
| Ingress Gateway | `public` |
| HTTPS secret | `public-https-tls` |

## 실행 절차

1. Kubernetes context, Argo CD와 기존 `bootstrap` ApplicationSet 상태를 확인한다. 이 문서는 ApplicationSet이 생성한 세 Application을 독립 manifest 관리로 이관한다. Cilium은 최소 설치 상태여야 한다.

   ```sh
   kubectl --context cpa get nodes
   kubectl --context cpa -n argo get application argo-apps
   kubectl --context cpa -n argo get applicationset bootstrap
   ```

2. 이 PR 병합본을 `argo-apps` Application에 동기화한다. 이 동기화는 세 독립 Application manifest를 기존 ApplicationSet 소유 객체에 적용한다. 이 시점에는 ApplicationSet을 아직 삭제하지 않는다.

   ```sh
   kubectl --context cpa -n argo patch application argo-apps \
     --type=merge \
     --patch '{"operation":{"sync":{"prune":false}}}'
   kubectl --context cpa -n argo wait \
     --for=jsonpath='{.status.operationState.phase}'=Succeeded \
     application/argo-apps \
     --timeout=10m
   ```

3. `bootstrap` ApplicationSet을 고아화 삭제한다. 세 Application은 유지하되, ApplicationSet owner reference와 bootstrap 단계 label만 제거한다. `bootstrap`에는 `Delete=false,Prune=false`가 설정되어 있으므로 Git에서 manifest가 사라져도 이 수동 삭제가 필요하다.

   ```sh
   kubectl --context cpa -n argo delete applicationset bootstrap --cascade=orphan
   kubectl --context cpa -n argo label application \
     cilium istio-system istio-gateways \
     ghilbut.com/bootstrap-stage-
   kubectl --context cpa -n argo get applications \
     -o 'custom-columns=NAME:.metadata.name,OWNER:.metadata.ownerReferences[0].kind'
   ```

4. Cilium Application을 동기화하고 Healthy 상태를 확인한다. 완료 전에는 Istio system을 동기화하지 않는다.

   ```sh
   kubectl --context cpa -n argo patch application cilium \
     --type=merge \
     --patch '{"operation":{"sync":{"prune":false}}}'
   kubectl --context cpa -n argo wait \
     --for=jsonpath='{.status.health.status}'=Healthy \
     application/cilium \
     --timeout=20m
   ```

5. `istio-system` Application을 동기화하고 Healthy 상태를 확인한다. 이 Application은 Istio base CRD, `istiod`, `istio-system` namespace를 하나의 health 경계로 관리한다. `istiod`는 namespace 기본 injection을 비활성화한 상태에서 실행한다.

   ```sh
   kubectl --context cpa -n argo patch application istio-system \
     --type=merge \
     --patch '{"operation":{"sync":{"prune":false}}}'
   kubectl --context cpa -n argo wait \
     --for=jsonpath='{.status.health.status}'=Healthy \
     application/istio-system \
     --timeout=20m
   kubectl --context cpa get crd gateways.networking.istio.io
   kubectl --context cpa -n istio-system wait \
     --for=condition=Available deployment/istiod \
     --timeout=10m
   ```

6. `istio-gateways` Application을 동기화하고 ingress gateway Deployment가 Available이 될 때까지 기다린다. 이 단계는 `istio-system` Application이 Healthy가 된 후에만 시작된다. 따라서 injection webhook이 준비되기 전에 `image: auto` gateway Pod가 생성되지 않는다.

   ```sh
   kubectl --context cpa -n argo patch application istio-gateways \
     --type=merge \
     --patch '{"operation":{"sync":{"prune":false}}}'
   kubectl --context cpa -n argo wait \
     --for=jsonpath='{.status.health.status}'=Healthy \
     application/istio-gateways \
     --timeout=20m
   kubectl --context cpa -n istio-gateways wait \
     --for=condition=Available deployment/istio-ingressgateway \
     --timeout=10m
   kubectl --context cpa -n istio-gateways get service istio-ingressgateway
   kubectl --context cpa -n istio-gateways get deployment istio-ingressgateway \
     -o jsonpath='{.spec.template.spec.containers[?(@.name=="istio-proxy")].image}{"\n"}'
   kubectl --context cpa -n istio-gateways get gateway public
   kubectl --context cpa -n istio-gateways get authorizationpolicy public-hosts
   ```

7. TLS secret이 아직 없음을 확인하고 여기서 멈춘다. `public`은 HTTP 요청을 HTTPS로 redirect하지만, HTTPS listener는 cert-manager가 secret을 만든 뒤에만 사용할 수 있다. 이 단계에서는 public DNS, Certificate, VirtualService를 만들거나 HTTPS endpoint를 성공으로 판정하지 않는다.

   ```sh
   kubectl --context cpa -n istio-gateways get secret public-https-tls --ignore-not-found
   ```

   cert-manager, external-dns, Keycloak 공개 route 작업을 완료한 뒤에 `id.ghilbut.com`을 검증한다.

## 결과

- 실행 일시:
- 실행자:
- `bootstrap` ApplicationSet 고아화 삭제:
- Cilium Application 확인:
- `istio-system` Application과 `istiod` Deployment 확인:
- `istio-gateways` Application, ingress gateway Deployment와 LoadBalancer Service 확인:
- `public` Gateway와 host AuthorizationPolicy 확인:
- TLS secret과 후속 공개 route 작업 대기:
