resource "aws_account_region" "opt_in" {
  for_each = var.disabled_opt_in_regions

  region_name = each.value
  enabled     = false
}
