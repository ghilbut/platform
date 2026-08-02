variable "instance_arn" {
  description = "IAM Identity Center 인스턴스 ARN입니다."
  type        = string
}

variable "name" {
  description = "IAM Identity Center permission set 이름입니다."
  type        = string
}

variable "description" {
  description = "IAM Identity Center permission set 설명입니다."
  type        = string
}

variable "session_duration" {
  description = "IAM Identity Center 세션 유지 시간입니다."
  type        = string
  default     = "PT4H"
}

variable "managed_policy_arns" {
  description = "permission set에 연결할 AWS 관리형 IAM 정책 ARN 집합입니다."
  type        = set(string)
  default     = []
}

variable "inline_policy" {
  description = "permission set에 연결할 선택적 IAM inline policy JSON입니다."
  type        = string
  default     = null
  nullable    = true
}

variable "account_assignments" {
  description = "permission set을 할당할 AWS 계정과 IAM Identity Center principal 집합입니다."
  type = map(object({
    account_id     = string
    principal_id   = string
    principal_type = string
  }))
}
