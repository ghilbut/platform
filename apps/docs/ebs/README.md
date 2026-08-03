---
type: guide
area: apps
application: ebs
---

# OpenEBS

CPA의 OpenEBS LVM LocalPV는 host에서 준비한 `openebs` LVM volume group에 PVC별 Logical Volume을 생성한다. Helm chart는 CSI driver를 설치하고, StorageClass는 volume group 이름만 선택한다.

## 연결

- [Applications Documents RULEBOOK](../RULEBOOK.md)
- [Argo CD Application](../../argo-apps/ebs.yaml)
- [OpenEBS manifest 디렉터리](../../argo-apps/ebs/)
- [K3s 구성 디렉터리](../../../k3s/)
