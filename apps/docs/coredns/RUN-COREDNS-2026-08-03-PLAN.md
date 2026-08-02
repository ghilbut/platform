---
type: run
area: apps
application: coredns
cluster: cpa
status: planned
planned_at: 2026-08-03
paused_at:
paused_step:
paused_reason:
completed_at:
---

# CoreDNS 설치 실행 계획 — 2026-08-03

PR이 `main`에 병합된 뒤 실행한다. 관련 경로는 [CoreDNS README](README.md)에서 확인한다. 이 문서는 [Applications Documents RULEBOOK](../RULEBOOK.md), [RUN-PLAN](../../../docs/obsidian/templates/RUN-PLAN.md) 템플릿과 [Documentation RULEBOOK RUNBOOK](../../../docs/RULEBOOK.md#runbook)을 따른다.

## 실행 값

| 항목 | 값 |
| --- | --- |
| Kubernetes context | `cpa` |
| Namespace | `coredns` |
| DNS listen address | `192.168.254.4:53` TCP, UDP |
| Local zones | `ghilbut.com`, `ghilbut.net` |
| Local record store | `coredns/etcd` Service |
| Public resolvers | `1.1.1.1`, `1.0.0.1`, `8.8.8.8`, `8.8.4.4` |
| etcd storage | `etcd-data-coredns-0`, `openebs-lvm`, `1Gi` |

## 실행 절차

1. CPA node IP와 host DNS listener를 확인한다. CoreDNS Helm chart는 `hostPort: 53`을 사용하므로 `systemd-resolved` stub listener를 끄고 host resolver를 `/run/systemd/resolve/resolv.conf`로 전환한다. 이 변경 뒤 `192.168.254.4:53`과 loopback 53을 사용하는 프로세스가 없어야 한다.

   ```sh
   ssh cpa 'sudo install -d -m 755 /etc/systemd/resolved.conf.d'
   ssh cpa 'printf "[Resolve]\\nDNSStubListener=no\\n" | sudo tee /etc/systemd/resolved.conf.d/coredns.conf >/dev/null'
   ssh cpa 'sudo ln -sfn /run/systemd/resolve/resolv.conf /etc/resolv.conf'
   ssh cpa 'sudo systemctl restart systemd-resolved'
   ssh cpa 'ip -brief address show; sudo ss -lntup | grep -E "(:53|:2379|:2380)\\b" || true; resolvectl status'
   ```

2. host firewall이 활성 상태이면 CPA node IP의 TCP·UDP 53 inbound를 허용한다. UFW가 비활성인 CPA에서는 이 명령을 실행하지 않는다. 상위 router나 firewall이 있으면 같은 TCP·UDP 53 규칙을 추가한다.

   ```sh
   ssh cpa 'sudo ufw status verbose'
   ssh cpa 'sudo ufw allow in proto tcp to 192.168.254.4 port 53'
   ssh cpa 'sudo ufw allow in proto udp to 192.168.254.4 port 53'
   ```

3. CoreDNS Application을 동기화하고 etcd-operator, etcd Cluster, PVC, DNS Deployment를 확인한다. etcd client port는 host에 노출하지 않는다.

   ```sh
   kubectl --context cpa -n argo patch application coredns \
     --type=merge \
     --patch '{"operation":{"sync":{"prune":true}}}'
   kubectl --context cpa -n argo wait \
     --for=jsonpath='{.status.operationState.phase}'=Succeeded \
     application/coredns \
     --timeout=15m
   kubectl --context cpa -n etcd-operator-system wait \
     --for=condition=Available deployment/etcd-operator-controller-manager \
     --timeout=10m
   kubectl --context cpa -n coredns wait \
     --for=condition=Ready statefulset/coredns \
     --timeout=10m
   kubectl --context cpa -n coredns wait \
     --for=condition=Available deployment/coredns \
     --timeout=10m
   kubectl --context cpa -n coredns get etcdcluster,pvc,service,statefulset,deployment
   ```

4. CPA host address에서 TCP와 UDP DNS를 확인한다. local etcd record 작성과 제거는 [CoreDNS RUNBOOK](RUNBOOK.md)을 따른다. etcd에 record가 없는 name의 응답은 Cloudflare 또는 Google Public DNS 결과와 같아야 한다.

   ```sh
   dig @192.168.254.4 ghilbut.com A
   dig +tcp @192.168.254.4 ghilbut.com A
   dig @1.1.1.1 ghilbut.com A
   dig @8.8.8.8 ghilbut.com A
   ```

## 결과

- 실행 일시:
- 실행자:
- 53/TCP·UDP host listener와 firewall 확인:
- etcd-operator, PVC와 StatefulSet 확인:
- CoreDNS Deployment 확인:
- local lookup과 public fallback 확인:
