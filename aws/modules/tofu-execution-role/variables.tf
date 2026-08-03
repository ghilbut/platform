variable "name" {
  description = "생성할 IAM 실행 역할 이름입니다."
  type        = string
}

variable "description" {
  description = "생성할 IAM 실행 역할 설명입니다."
  type        = string
}

variable "source_account_id" {
  description = "IAM Identity Center permission set이 프로비저닝된 AWS 계정 ID입니다."
  type        = string
}

variable "source_permission_set_name" {
  description = "실행 역할을 수임할 IAM Identity Center permission set 이름입니다."
  type        = string
}

variable "sso_region" {
  description = "IAM Identity Center 리전입니다."
  type        = string
  default     = "us-east-1"
}

variable "managed_policy_arns" {
  description = "실행 역할에 연결할 AWS 관리형 IAM 정책 ARN 집합입니다."
  type        = set(string)
  default     = []
}

variable "inline_policy" {
  description = "실행 역할에 연결할 선택적 IAM inline policy JSON입니다."
  type        = string
  default     = null
  nullable    = true
}

variable "max_session_duration" {
  description = "실행 역할의 최대 세션 시간(초)입니다."
  type        = number
  default     = 14400
}
