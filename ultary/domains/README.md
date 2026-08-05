# Ultary, Inc.의 Domain 정책

## OpenTofu access

`ultary/domains/tofu/`는 account-local execution role을 사용하지 않는다. AWS provider는
`AWS_PROFILE`의 source identity를 직접 사용한다. Backend는 Plan에서 SharedServices
`tofu-state-readonly`, Apply에서 SharedServices `tofu-state-apply`를 수임한다. Plan은
`ghilbut-tofu-plan-for-ultary-domains`, Apply는 `ghilbut-tofu-apply-for-ultary-domains`를 지정한다.
Profile이나 backend role을 전환할 때 `tofu init -reconfigure`를 실행한다. Apply는
`-backend-config=tofu-state-apply.tfbackend`를 함께 지정한다. 이 root에는
`tofu-apply.auto.tfvars`를 만들지 않는다.

## ultary

### ultary.co

* 메인 서비스 도메인이다.
* ultary.com은 선점되어 ultary.co로 사용한다.

### ~ultary.net~

* ~내부 구성원들을 위한 그룹웨어 및 중앙 지원 시스템을 위한 도메인이다.~

### ultary.io

* ServiceAccount와 SPIFFE 등을 위한 도메인이다. 사람을 위한 용도로는 사용하지 않는다.

## Dokevy

### dokevy.com

* 모든 서비스를 위한 핵심 플랫폼을 위한 도메인이다.
* 최대한 오픈소스와 외부 서비스로 구성되어 인하우 시스템의 장애 등에 영향을 받지 않도록 한다.

### dokevy.net

* 내부 네트워크 전용으로 인터넷에 노출되지 않는 엔드포인트를 위해 존재한다.

### dokevy.io

* 아직 용도를 정하지 않았다.

## Polykube

### polykube.com

* Kubernetes as a Service를 윈한 도메인이다.
* ultary.co가 포관적인 업무 지원 서비스라면, polykube는 DevX와 DevSecFinOps에 포커스 된 서비스이다.

### polykube.net

* 아직 용도를 정하지 않았다.

### polykube.io

* 아직 용도를 정하지 않았다.
