---
type: runbook
area: apps
application: vault
cluster: cpa
---

# Vault 운영 RUNBOOK

- [설치](#설치)
- [초기화](#초기화)
- [auto-unseal 재시작 검증](#auto-unseal-재시작-검증)
- [수동 Raft snapshot](#수동-raft-snapshot)
- [자동 백업 설계](#자동-백업-설계)
- [일상 확인](#일상-확인)
- [복구와 이전](#복구와-이전)

Vault 구성과 관련 경로는 [Vault README](README.md)에서 확인한다. 문서 작성 규칙은 [Applications Documents RULEBOOK](../RULEBOOK.md)을 따른다. snapshot 복원과 다른 workload 이전은 [Vault 복구 PLAYBOOK](PLAYBOOK.md)을 따른다.

## 현재 구성

| 항목 | 값 |
| --- | --- |
| Kubernetes context | `cpa` |
| namespace / ServiceAccount | `vault` / `vault` |
| Vault Pod | `vault-0` |
| storage | Integrated Raft, `data-vault-0` 10 GiB PVC |
| seal | AWS KMS `alias/platform-vault` |
| AWS 인증 | CPA ServiceAccount OIDC federation, `platform-vault` 역할 |
| recovery key | 5개 생성, 3개 필요 |

Raft snapshot은 Vault 데이터 전체를 포함한다. 파일은 암호화된 백업 저장소에만 보관하고 일반 파일 공유, CI artifact, Git에 넣지 않는다.

## 설치

PR이 `main`에 병합된 뒤에만 설치한다. Vault Argo CD Application의 `targetRevision`은 `main`이므로, 병합 전 branch에서 OpenTofu를 적용하거나 Argo CD를 동기화하지 않는다.

### AWS 리소스 생성

`apps/tofu`는 CPA OIDC provider, `platform-vault` 역할, Vault AWS KMS seal key를 생성한다. 실제 적용 전 plan의 생성 대상과 AWS 계정이 platform인지 확인한다.

```sh
cd apps/tofu
tofu init
tofu plan
tofu apply
```

### Argo CD 배포와 확인

Argo CD에 Vault Application을 등록하고 수동 동기화한다. 이 Application에는 자동 동기화 정책이 없으므로 `argocd app sync` 또는 Argo CD UI에서 명시적으로 동기화해야 한다. Argo CD는 namespace와 `data-vault-0` PVC를 Helm StatefulSet보다 먼저 생성한다.

```sh
kubectl --context cpa -n argo apply -f apps/argo-apps/vault.yaml
argocd app sync vault
kubectl --context cpa get namespace vault
kubectl --context cpa -n vault get serviceaccount,pvc,pod
kubectl --context cpa -n vault rollout status statefulset/vault --timeout=10m
kubectl --context cpa -n vault exec vault-0 -- vault status
```

마지막 명령은 `Seal Type: awskms`, `Initialized: false`를 보여야 한다. `Initialized: true`이면 새로 초기화하지 않고 기존 Vault 상태를 확인한다. OpenTofu와 Argo CD는 Vault 초기화를 수행하지 않는다.

`data-vault-0` PVC와 namespace에는 `Delete=false,Prune=false`가 설정되어 있다. Vault Application을 삭제하거나 Git에서 해당 manifest를 제거해도 Argo CD는 이를 삭제하지 않는다. PV는 이 PVC가 소비될 때 OpenEBS가 동적으로 생성하며, `claimRef`로 PVC를 추적한다. PVC 또는 PV의 수동 삭제는 데이터 폐기 작업이므로 snapshot을 확인하고 승인된 변경 절차로만 수행한다.

## 초기화

초기화는 자동화하지 않는다. 지정된 비밀 보관 담당자가 직접 실행하고 root token과 recovery key를 즉시 수령한다. root token이나 recovery key를 Kubernetes Secret, ConfigMap, Pod 파일 시스템, 셸 히스토리, CI 로그에 저장하지 않는다.

### 초기화 전 확인

```sh
kubectl --context cpa get namespace vault
kubectl --context cpa -n vault get serviceaccount vault
kubectl --context cpa -n vault get pod vault-0
kubectl --context cpa -n vault exec vault-0 -- vault status
```

다음 상태에서만 초기화한다.

- `Seal Type`이 `awskms`다.
- `Initialized`가 `false`다.
- `vault-0`이 `Running`이다.

`Initialized`가 `true`이면 `vault operator init`을 다시 실행하지 않는다. 기존 root token과 recovery key를 다시 발급할 수 없다.

### 수동 초기화와 수령

초기화자는 비밀 출력을 받을 수 있는 직접 제어 터미널에서 다음 명령을 실행한다.

```sh
kubectl --context cpa -n vault exec -it vault-0 -- \
  vault operator init \
  -recovery-shares=5 \
  -recovery-threshold=3 \
  -format=json
```

출력의 `root_token`은 초기 운영 설정에만 사용한다. `recovery_keys_b64`의 5개 값은 서로 다른 수탁자와 보관 위치에 한 개씩 전달한다. PGP 공개키가 준비되어 있으면 `-recovery-pgp-keys`와 `-root-token-pgp-key`를 추가해 수령자별로 암호화된 출력을 사용한다.

초기화 직후 상태를 확인한다.

```sh
kubectl --context cpa -n vault exec vault-0 -- vault status
```

`Initialized`는 `true`, `Sealed`는 `false`여야 한다. `Sealed`가 `true`이면 AWS KMS 권한과 ServiceAccount OIDC federation을 조사한다. AWS KMS auto-unseal 구성에서 recovery key는 `vault operator unseal`에 사용하지 않는다.

### 초기 설정과 root token 폐기

root token으로 운영자 policy와 운영자 identity를 만들고, 해당 identity로 로그인할 수 있음을 확인한다. 그 뒤 root token을 폐기한다. root token을 잃은 경우 recovery key 3개로 `vault operator generate-root`를 수행한다. 기존 root token은 조회할 수 없다.

## auto-unseal 재시작 검증

초기화가 끝나고 첫 snapshot을 검증한 뒤, 계획된 점검 시간에 Pod 재생성으로 AWS KMS auto-unseal을 확인한다. 단일 replica이므로 이 작업 동안 Vault API를 사용할 수 없다.

StatefulSet, namespace, PVC, PV를 삭제하지 않고 Pod만 삭제한다.

```sh
kubectl --context cpa -n vault delete pod vault-0
kubectl --context cpa -n vault rollout status statefulset/vault --timeout=10m
kubectl --context cpa -n vault exec vault-0 -- vault status
```

새 Pod의 `Seal Type`은 `awskms`, `Initialized`는 `true`, `Sealed`는 `false`여야 한다. `Sealed`가 `true`이면 KMS key 상태, `platform-vault` 역할의 KMS 권한, ServiceAccount OIDC federation을 확인한다. PVC 또는 PV를 삭제해 재시작을 검증하지 않는다.

## 수동 Raft snapshot

자동 백업이 배포되기 전, 변경 작업 전후와 복구 훈련 시 수동 snapshot을 만든다. root token을 사용하지 않는다. snapshot endpoint만 사용할 수 있는 승인된 운영자 token을 사용한다.

### 생성과 검증

첫 터미널에서 Pod의 Vault API를 관리자 컴퓨터의 loopback에만 연결한다.

```sh
kubectl --context cpa -n vault port-forward pod/vault-0 8200:8200
```

둘째 터미널에서 저장 위치를 생성하고 token을 화면에 표시하지 않고 입력한다.

```sh
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_CLIENT_TIMEOUT='10m'
export SNAPSHOT_FILE="$PWD/vault-$(date -u +%Y%m%dT%H%M%SZ).snap"
umask 077
read -rs VAULT_TOKEN
export VAULT_TOKEN
vault operator raft snapshot save "$SNAPSHOT_FILE"
vault operator raft snapshot inspect "$SNAPSHOT_FILE"
shasum -a 256 "$SNAPSHOT_FILE"
unset VAULT_TOKEN
```

snapshot 파일과 SHA-256 checksum을 승인된 암호화 백업 저장소로 함께 전송한다. 전송 뒤 관리자 컴퓨터의 임시 파일을 삭제한다. `snapshot inspect`와 checksum 기록이 없는 snapshot은 복원에 사용하지 않는다.

## 자동 백업 설계

Vault Community Edition은 자동 snapshot 저장소를 제공하지 않는다. 자동 백업은 별도 backup workload가 Vault API로 snapshot을 받고 S3 같은 승인된 저장소로 전송하는 방식으로 구현한다.

자동화에는 다음을 적용한다.

- Vault 운영자나 root token을 사용하지 않는다. snapshot API 전용 Vault policy와 짧은 수명의 Vault token을 사용한다.
- backup workload는 별도 Kubernetes ServiceAccount와 별도 AWS IAM 역할을 사용한다. Vault 역할, cert-manager 역할, external-dns 역할과 공유하지 않는다.
- S3 권한은 전용 bucket과 backup prefix의 쓰기·목록·복원 읽기 권한으로 제한한다. bucket 암호화와 versioning을 사용한다.
- schedule, retention 기간, 저장소 위치, 복구 훈련 주기를 자동화 구현과 함께 기록한다.

## 일상 확인

```sh
kubectl --context cpa -n vault get pod,pvc
kubectl --context cpa -n vault exec vault-0 -- vault status
```

snapshot 이후에는 backup 객체 존재, checksum 일치, 암호화 상태를 확인한다. 데이터 손실 또는 workload 이전 시에는 [Vault 복구 PLAYBOOK](PLAYBOOK.md)을 사용한다.

## 복구와 이전

Raft snapshot 복원은 대상 Vault의 전체 상태를 snapshot 시점으로 바꾼다. 현재 Vault 위에 임의로 복원하지 않는다. 같은 workload의 데이터 손실 복구와 다른 namespace 또는 cluster workload로의 이전은 모두 [Vault 복구 PLAYBOOK](PLAYBOOK.md)을 따른다.
