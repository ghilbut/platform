---
type: rulebook
area: k8s
---

# Kubernetes Security

Kubernetes의 관측 접근은 [[knowledge/rulebooks/SECURITY|보안 기준]]을 따른다. 리소스 이름,
상태, `event`, `metric`과 `Secret` 값이 제거된 `manifest`와 `log`는 허용한다. `Secret` 값과
workload 데이터는 거부한다.

## Pod Security Standards

[Kubernetes Pod Security Admission](https://kubernetes.io/docs/concepts/security/pod-security-admission/)은 Namespace별 `enforce`, `audit`, `warn` label로 [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)를 적용한다.

- 일반 application Namespace는 `restricted`를 `enforce`, `audit`, `warn`에 적용한다.
- host device, hostPath, privileged container가 필요한 infrastructure Namespace는 필요한 범위에서만 `privileged`를 `enforce`에 적용하고 `restricted`를 `audit`, `warn`에 적용한다.
- 각 policy version은 `latest`를 사용한다. Kubernetes upgrade 후 새 security requirement는 `audit`과 `warn`에서 확인한다.

```yaml
metadata:
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/enforce-version: latest
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/audit-version: latest
    pod-security.kubernetes.io/warn: restricted
    pod-security.kubernetes.io/warn-version: latest
```

`restricted` policy로 실행할 수 없는 workload는 해당 Namespace에서만 `enforce: privileged`를 사용한다. `audit`과 `warn`은 `restricted`를 유지한다.
