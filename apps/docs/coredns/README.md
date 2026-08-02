---
type: guide
area: apps
application: coredns
---

# CoreDNS

CPA host `192.168.254.4:53`에서 `ghilbut.com`, `ghilbut.net`을 etcd로 먼저 조회한다. 없는 record는 Cloudflare와 Google Public DNS로 조회한다. 공식 etcd-operator가 etcd Cluster와 PVC를 관리하고, official CoreDNS Helm chart가 DNS workload를 관리한다. etcd는 cluster 내부 headless Service로만 연결하며 K3s embedded etcd와 분리한다.

## 연결

- [Argo CD Application](../../argo-apps/coredns.yaml)
- [CoreDNS manifest 디렉터리](../../argo-apps/coredns/)
- [K3s 구성 디렉터리](../../../k3s/)
