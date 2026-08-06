---
title: AWS CDN
---

# AWS CDN

`aws/cdn/`은 SharedServices account의 CDN resource와 배포 코드를 관리한다. account, state와 execution role은 [[aws/README|AWS architecture]]를 따른다.

## 이름과 tag

- CDN root provider `default_tags`는 `created_by`, `managed_by`, `project`, `service`, `opentofu/repo`, `opentofu/path`을 제공한다.
- CDN module은 `local.default_tags`에 `opentofu/module/repo`, `opentofu/module/path`만 추가한다. `var.default_tags`를 module input으로 전달하지 않는다.
- CDN resource 이름과 `Name` tag는 `cdn-platform`을 기준으로 한다. S3 bucket처럼 전역 이름 충돌을 막아야 하는 resource에만 `ghilbut-` 접두사를 사용한다.
- S3 object에는 `Name` tag를 붙이지 않는다. object tag는 10개 제한 안에 둔다.

## CI 적용 범위

CDN CI는 `404.html`, `503.html`, `lambda.zip`, Lambda@Edge와 CloudFront distribution만 적용한다. IAM, DNS, ACM, CloudFront Function 변경은 로컬 OpenTofu Apply가 관리한다.

Lambda bundle은 git에서 관리한다. CI는 build 결과가 저장소와 일치하는지 확인한 뒤 bundle을 적용한다.
