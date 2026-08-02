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
| ApplicationSet | `bootstrap` |
| Argo CD Applications | `cilium`, `istio-system`, `istio-gateways` |
| Ingress Service | `istio-ingressgateway` |
| Ingress Gateway | `public` |
| HTTPS secret | `public-https-tls` |

## 실행 절차

1. Kubernetes context와 Argo CD bootstrap 상태를 확인한다. 이 PR은 기존 static Application을 ApplicationSet 소유 Application으로 교체한다. Cilium은 최소 설치 상태이며, bootstrap이 새 Cilium Application을 생성한 뒤 첫 RollingSync 단계를 실행한다.

   ```sh
   kubectl --context cpa get nodes
   kubectl --context cpa -n argo get application argo-apps
   ```

2. Argo CD Application을 동기화해 Progressive Syncs를 활성화한다. `argo-apps`가 `bootstrap` ApplicationSet을 적용하더라도, 이 설정이 반영되기 전에는 RollingSync가 시작되지 않는다.

   ```sh
   kubectl --context cpa -n argo patch application argo \
     --type=merge \
     --patch '{"operation":{"sync":{"prune":false}}}'
   kubectl --context cpa -n argo wait \
     --for=jsonpath='{.status.operationState.phase}'=Succeeded \
     application/argo \
     --timeout=10m
   kubectl --context cpa -n argo rollout status \
     deployment/cd-applicationset-controller \
     --timeout=10m
   kubectl --context cpa -n argo get configmap argocd-cmd-params-cm \
     -o jsonpath='{.data.applicationsetcontroller\.enable\.progressive\.syncs}{"\n"}'
   ```

3. `bootstrap` ApplicationSet과 Cilium Application을 확인한다. RollingSync가 Cilium을 동기화하고 `Healthy` 상태가 된 뒤에만 Istio system 단계를 시작한다. child Application을 수동 동기화하지 않는다.

   ```sh
   kubectl --context cpa -n argo get applicationset bootstrap
   kubectl --context cpa -n argo wait \
     --for=jsonpath='{.status.health.status}'=Healthy \
     application/cilium \
     --timeout=20m
   kubectl --context cpa -n argo get application cilium
   ```

4. `istio-system` Application이 생성되고 Healthy가 될 때까지 기다린다. 이 Application은 Istio base CRD, `istiod`, `istio-system` namespace를 하나의 health 경계로 관리한다. `istiod`는 namespace 기본 injection을 비활성화한 상태에서 실행한다.

   ```sh
   kubectl --context cpa -n argo wait \
     --for=create \
     application/istio-system \
     --timeout=20m
   kubectl --context cpa -n argo wait \
     --for=jsonpath='{.status.health.status}'=Healthy \
     application/istio-system \
     --timeout=20m
   kubectl --context cpa get crd gateways.networking.istio.io
   kubectl --context cpa -n istio-system wait \
     --for=condition=Available deployment/istiod \
     --timeout=10m
   ```

5. `istio-gateways` Application이 생성되고 ingress gateway Deployment가 Available이 될 때까지 기다린다. 이 단계는 `istio-system` Application이 Healthy가 된 후에만 시작된다. 따라서 injection webhook이 준비되기 전에 `image: auto` gateway Pod가 생성되지 않는다.

   ```sh
   kubectl --context cpa -n argo wait \
     --for=create \
     application/istio-gateways \
     --timeout=20m
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

6. TLS secret이 아직 없음을 확인하고 여기서 멈춘다. `public`은 HTTP 요청을 HTTPS로 redirect하지만, HTTPS listener는 cert-manager가 secret을 만든 뒤에만 사용할 수 있다. 이 단계에서는 public DNS, Certificate, VirtualService를 만들거나 HTTPS endpoint를 성공으로 판정하지 않는다.

   ```sh
   kubectl --context cpa -n istio-gateways get secret public-https-tls --ignore-not-found
   ```

   cert-manager, external-dns, Keycloak, Vault 공개 route 작업을 완료한 뒤에 `id.ghilbut.com`과 `vault.ghilbut.com`을 검증한다.

## 결과

- 실행 일시:
- 실행자:
- `bootstrap` ApplicationSet 확인:
- Cilium Application 확인:
- `istio-system` Application과 `istiod` Deployment 확인:
- `istio-gateways` Application, ingress gateway Deployment와 LoadBalancer Service 확인:
- `public` Gateway와 host AuthorizationPolicy 확인:
- TLS secret과 후속 공개 route 작업 대기:
