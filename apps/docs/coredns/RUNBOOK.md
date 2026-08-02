---
type: runbook
area: apps
application: coredns
---

# CoreDNS RUNBOOK

CoreDNS와 etcd의 설치·노출 값은 [CoreDNS README](README.md)와 [CoreDNS 실행 계획](RUN-COREDNS-2026-08-03-PLAN.md)을 따른다.

## etcd record 관리

CoreDNS etcd plugin은 SkyDNS 형식의 JSON value를 사용한다. `ghilbut.com`과 `ghilbut.net`은 `/skydns` 아래에 역순 label로 저장한다. 예를 들어 `test.ghilbut.com`의 A record key는 `/skydns/com/ghilbut/test`다.

1. 임시 etcdctl Pod에서 record를 추가하거나 갱신한다. `<record-name>`과 `<ipv4-address>`를 실제 값으로 바꾼다.

   ```sh
   kubectl --context cpa -n coredns run etcdctl \
     --image=quay.io/coreos/etcd@sha256:8820feb533fccb2bfaff581261a0f508a4ec3e56f38ed43efae659d882999e32 \
     --restart=Never \
     --rm -it \
     --env=ETCDCTL_API=3 \
     -- /usr/local/bin/etcdctl \
     --endpoints=http://etcd-0.etcd.coredns.svc.cluster.local:2379 \
     put /skydns/com/ghilbut/<record-name> '{"host":"<ipv4-address>","ttl":60}'
   ```

2. CPA host DNS endpoint에서 record를 확인한다.

   ```sh
   dig @192.168.254.4 <record-name>.ghilbut.com A
   ```

3. 더 이상 필요하지 않은 record는 같은 key를 삭제한다. 삭제 뒤 local CoreDNS는 public resolver fallback을 사용한다.

   ```sh
   kubectl --context cpa -n coredns run etcdctl \
     --image=quay.io/coreos/etcd@sha256:8820feb533fccb2bfaff581261a0f508a4ec3e56f38ed43efae659d882999e32 \
     --restart=Never \
     --rm -it \
     --env=ETCDCTL_API=3 \
     -- /usr/local/bin/etcdctl \
     --endpoints=http://etcd-0.etcd.coredns.svc.cluster.local:2379 \
     del /skydns/com/ghilbut/<record-name>
   ```
