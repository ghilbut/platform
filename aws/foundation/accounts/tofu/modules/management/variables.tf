variable "disabled_opt_in_regions" {
  description = "비활성 상태를 유지할 opt-in AWS 리전 이름 집합입니다."
  type        = set(string)
}
