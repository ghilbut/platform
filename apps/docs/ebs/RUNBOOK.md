---
type: runbook
area: apps
application: ebs
---

# OpenEBS RUNBOOK

이 문서는 [Applications Documents RULEBOOK](../RULEBOOK.md), [Documentation RULEBOOK RUNBOOK](../../../docs/RULEBOOK.md#runbook), [OpenEBS README](README.md)를 따른다. `openebs` volume group의 준비·확인 절차만 다루며, LVM LocalPV Helm chart는 device를 초기화하지 않는다.

## LVM volume group 준비

`/dev/sda10`은 존재하는 partition일 때만 대상 예시로 사용한다. mount, LVM, RAID 또는 filesystem에 사용 중인 device에는 이 절차를 실행하지 않는다.

1. device와 현재 LVM 상태를 읽기 전용으로 확인한다.

   ```sh
   ssh cpa 'lsblk -f /dev/sda'
   ssh cpa 'sudo blkid /dev/sda10 || true'
   ssh cpa 'sudo pvs; sudo vgs; sudo findmnt -S /dev/sda10 || true; sudo wipefs -n /dev/sda10'
   ```

2. `openebs` volume group이 없고 `/dev/sda10`이 비어 있음이 확인된 경우, Physical Volume과 volume group을 만든다. `pvcreate`는 기존 filesystem signature를 덮어쓸 수 있다.

   ```sh
   ssh cpa 'sudo pvcreate /dev/sda10'
   ssh cpa 'sudo vgcreate openebs /dev/sda10'
   ```

3. `openebs` volume group이 이미 있고, 검증한 새 device를 용량 확장에 사용하려면 해당 device만 Physical Volume으로 만든 뒤 group에 추가한다.

   ```sh
   ssh cpa 'sudo pvcreate /dev/sda10'
   ssh cpa 'sudo vgextend openebs /dev/sda10'
   ```

4. volume group과 Kubernetes StorageClass를 확인한다.

   ```sh
   ssh cpa 'sudo pvs -o pv_name,vg_name,pv_size,pv_free; sudo vgs -o vg_name,vg_size,vg_free; sudo lvs'
   kubectl --context cpa get storageclass openebs-lvm -o yaml
   ```

## StorageClass 확인

`openebs-lvm` StorageClass는 `volgroup: openebs`를 사용한다. PVC가 생성되면 OpenEBS는 이 volume group에 Logical Volume을 만들고, PV의 node affinity로 CPA node에 연결한다.

```sh
kubectl --context cpa get pvc,pv -A
kubectl --context cpa get storageclass openebs-lvm -o jsonpath='{.parameters.volgroup}{"\\n"}'
```

## 금지 작업

- PVC 또는 PV가 존재하는 동안 `pvremove`, `vgreduce`, `vgremove`, `lvremove`을 실행하지 않는다.
- `/dev/sda10`이 이미 사용 중이면 `pvcreate` 또는 `wipefs`를 실행하지 않는다.
- device 준비는 Argo CD나 OpenEBS Helm chart의 책임이 아니다.
