---
type: runbook
area: apps
application: ebs
---

# OpenEBS RUNBOOK

이 문서는 [Applications Documents RULEBOOK](../RULEBOOK.md), [Documentation RULEBOOK RUNBOOK](../../../docs/RULEBOOK.md#runbook), [OpenEBS README](README.md)를 따른다. LVM LocalPV Helm chart는 device를 초기화하지 않는다. 최초 `openebs` volume group 생성은 [K3s 설치 RUNBOOK](../../../k3s/RUNBOOK.md#2-openebs-lvm-volume-group-준비)의 host 준비 절차를 따른다.

## LVM volume group 상태 확인

1. `openebs` volume group과 StorageClass를 확인한다.

   ```sh
   ssh cpa 'sudo pvs -o pv_name,vg_name,pv_size,pv_free; sudo vgs -o vg_name,vg_size,vg_free; sudo lvs'
   kubectl --context cpa get storageclass openebs-lvm -o yaml
   ```

## LVM volume group 확장

`openebs` volume group의 용량을 늘릴 때만 실행한다. 새 device가 mount, LVM, RAID 또는 filesystem에 사용 중이지 않음을 먼저 확인한다.

1. 새 device와 LVM 상태를 읽기 전용으로 확인한다. `<new-device>`를 실제 device path로 바꾼다.

   ```sh
   ssh cpa 'lsblk -f <new-device>; sudo blkid <new-device> || true'
   ssh cpa 'sudo pvs; sudo vgs; sudo findmnt -S <new-device> || true; sudo wipefs -n <new-device>'
   ```

2. 새 device가 비어 있음이 확인된 경우에만 Physical Volume을 만들고 `openebs` volume group에 추가한다. `pvcreate`는 기존 filesystem signature를 덮어쓸 수 있다.

   ```sh
   ssh cpa 'sudo pvcreate <new-device>'
   ssh cpa 'sudo vgextend openebs <new-device>'
   ```

3. 확장된 volume group을 확인한다.

   ```sh
   ssh cpa 'sudo pvs -o pv_name,vg_name,pv_size,pv_free; sudo vgs -o vg_name,vg_size,vg_free'
   ```

## StorageClass 확인

`openebs-lvm` StorageClass는 `volgroup: openebs`를 사용한다. PVC가 생성되면 OpenEBS는 이 volume group에 Logical Volume을 만들고, PV의 node affinity로 CPA node에 연결한다.

```sh
kubectl --context cpa get pvc,pv -A
kubectl --context cpa get storageclass openebs-lvm -o jsonpath='{.parameters.volgroup}{"\\n"}'
```

## 금지 작업

- PVC 또는 PV가 존재하는 동안 `pvremove`, `vgreduce`, `vgremove`, `lvremove`을 실행하지 않는다.
- 새 device가 이미 사용 중이면 `pvcreate` 또는 `wipefs`를 실행하지 않는다.
- device 준비는 Argo CD나 OpenEBS Helm chart의 책임이 아니다.
