---
type: playbook
area: apps
application: vault
cluster: cpa
---

# Vault 복구 PLAYBOOK

- [적용 범위](#적용-범위)
- [복원 전 준비](#복원-전-준비)
- [새 Vault workload 설치](#새-vault-workload-설치)
- [Raft snapshot 복원](#raft-snapshot-복원)
- [검증과 전환](#검증과-전환)

이 문서는 Integrated Raft snapshot으로 Vault 전체 상태를 복원하거나 다른 Kubernetes workload로 옮기는 절차다. 구성 경로는 [Vault README](README.md), 일상 운영과 수동 snapshot 생성은 [Vault 운영 RUNBOOK](RUNBOOK.md)을 따른다.

## 적용 범위

다음 상황에 사용한다.

- Vault PVC 또는 Raft 데이터가 손상되었거나 소실됐다.
- 새 namespace 또는 새 Kubernetes cluster의 Vault workload로 이동한다.
- 원본 Vault를 중단하기 전에 독립된 대상 workload에서 snapshot 복원을 검증한다.

snapshot 복원은 snapshot 생성 이후의 Vault 데이터와 설정을 되돌린다. 원본과 대상의 동시 쓰기를 허용하지 않는다.

## 복원 전 준비

1. 사용할 snapshot의 생성 시각, SHA-256 checksum, 저장소 위치를 확인한다.
2. 격리된 관리자 컴퓨터에 snapshot을 내려받고 checksum을 비교한다.
3. 복원 기간에는 원본 workload로 향하는 쓰기를 중지한다. 이동 작업이면 마지막 snapshot을 만든 뒤 원본 workload를 읽기 전용 상태로 유지한다.
4. source Vault의 AWS KMS key를 삭제하거나 교체하지 않는다. snapshot이 복원한 seal 설정은 source key로 auto-unseal한다.
5. 분리 보관한 source recovery key 3개 중 2개와 복원 뒤 사용할 운영자 identity를 확보한다. recovery key는 auto-unseal에 입력하지 않으며, source 운영자 identity를 복구해야 할 때 `generate-root`에 사용한다.

## 새 Vault workload 설치

복원 대상은 source와 분리된 빈 Raft storage로 시작한다. 원본 PVC를 대상 Pod에 붙이지 않는다.

1. 대상 namespace, Helm release, ServiceAccount 이름을 정한다. source와 같은 cluster에서 병행 검증하면 source와 다른 이름을 사용한다.
2. 대상 ServiceAccount subject만 신뢰하는 IAM 역할을 만든다. 다른 cluster라면 대상 cluster issuer의 IAM OIDC provider와 역할 trust policy를 추가한다.
3. 대상 역할에 source AWS KMS key의 `kms:Encrypt`, `kms:Decrypt`, `kms:DescribeKey` 권한을 부여한다. KMS alias가 source key를 가리키는지 확인한다.
4. 대상 Helm release 이름으로 `data-<release-name>-0` PVC를 먼저 만든다. source와 같은 storage class와 10 GiB 요청량을 사용하고, `Delete=false,Prune=false`와 Helm보다 이른 sync wave를 설정한다. 대상 PVC는 비어 있어야 한다.
5. source와 같은 Vault chart version 및 Raft storage 설정으로 대상 workload를 배포한다.
6. 대상 Pod가 `Running`이고 `vault status`의 `Initialized`가 `false`인지 확인한다.

대상 초기화는 source 운영 상태를 만들기 위한 것이 아니라 force restore API를 인증하기 위한 임시 bootstrap이다. 반드시 사람이 실행하고 이 단계에서 나온 임시 root token과 recovery key를 수령한다.

```sh
kubectl --context <target-context> -n <target-namespace> exec -it <target-pod> -- \
  vault operator init \
  -recovery-shares=3 \
  -recovery-threshold=2 \
  -format=json
```

임시 root token을 복원 단계에서만 사용한다. force restore 뒤 이 token과 임시 recovery key는 source snapshot의 상태로 대체되므로 보관하거나 운영에 사용하지 않는다.

## Raft snapshot 복원

첫 터미널에서 대상 Pod의 Vault API를 loopback에만 연결한다.

```sh
kubectl --context <target-context> -n <target-namespace> port-forward pod/<target-pod> 8200:8200
```

둘째 터미널에서 대상 bootstrap root token을 화면에 표시하지 않고 입력한 뒤 force restore를 실행한다. `-force`는 source와 대상의 auto-unseal 또는 recovery key 구성이 다를 수 있으므로 필요하다.

```sh
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_CLIENT_TIMEOUT='10m'
read -rs VAULT_TOKEN
export VAULT_TOKEN
vault operator raft snapshot restore -force <verified-snapshot-file>
unset VAULT_TOKEN
```

복원 중에는 대상 Pod를 삭제하거나 scale하지 않는다. 명령이 성공하면 다음 상태를 확인한다.

```sh
kubectl --context <target-context> -n <target-namespace> exec <target-pod> -- vault status
```

`Initialized`는 `true`, `Sealed`는 `false`여야 한다. `Sealed`가 `true`이면 source KMS key, 대상 IAM 역할, ServiceAccount OIDC federation을 확인하고 대상 workload를 한 번 재시작한 뒤 다시 확인한다. recovery key를 `vault operator unseal`에 입력하지 않는다.

## 검증과 전환

1. source에서 사용하던 비-root 운영자 identity로 대상에 로그인한다. 대상 bootstrap root token은 사용하지 않는다.
2. 필요한 secrets engine, auth method, policy, audit device가 snapshot 시점 상태로 존재하는지 확인한다.
3. 분리 보관한 recovery key 2개로 `vault operator generate-root`가 가능한지 복구 훈련 절차를 검증한다. 새 root token은 운영자 identity 복구에만 사용하고 즉시 폐기한다.
4. 애플리케이션의 Vault 주소와 인증 구성을 대상으로 바꾸고, 읽기와 쓰기 동작을 확인한다.
5. 대상 백업을 새로 만들고 checksum과 복원 절차를 확인한다.
6. 원본 workload, PVC, IAM 권한, KMS key는 대상 검증과 전환 완료 뒤에만 별도 변경한다.
