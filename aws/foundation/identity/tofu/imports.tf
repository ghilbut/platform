import {
  to = aws_identitystore_group.devops
  id = "d-906671970d/94183498-5041-705e-ddc0-aa6c2e714fbc"
}

import {
  to = aws_identitystore_group_membership.devops_ghilbut
  id = "d-906671970d/d4681438-c011-703c-628d-3a176b3f7b1f"
}

import {
  to = aws_ssoadmin_permission_set.tofu
  id = "arn:aws:sso:::permissionSet/ssoins-7223d00af1910289/ps-7223081e18fe0738,arn:aws:sso:::instance/ssoins-7223d00af1910289"
}

import {
  to = aws_ssoadmin_managed_policy_attachment.tofu["AdministratorAccess"]
  id = "arn:aws:iam::aws:policy/AdministratorAccess,arn:aws:sso:::permissionSet/ssoins-7223d00af1910289/ps-7223081e18fe0738,arn:aws:sso:::instance/ssoins-7223d00af1910289"
}

import {
  to = aws_ssoadmin_managed_policy_attachment.tofu["AWSOrganizationsFullAccess"]
  id = "arn:aws:iam::aws:policy/AWSOrganizationsFullAccess,arn:aws:sso:::permissionSet/ssoins-7223d00af1910289/ps-7223081e18fe0738,arn:aws:sso:::instance/ssoins-7223d00af1910289"
}

import {
  to = aws_ssoadmin_account_assignment.tofu["management_devops"]
  id = "94183498-5041-705e-ddc0-aa6c2e714fbc,GROUP,384959722788,AWS_ACCOUNT,arn:aws:sso:::permissionSet/ssoins-7223d00af1910289/ps-7223081e18fe0738,arn:aws:sso:::instance/ssoins-7223d00af1910289"
}

import {
  to = aws_ssoadmin_account_assignment.tofu["platform_ghilbut"]
  id = "7488a448-2051-70eb-80b8-106a98d83549,USER,869061964712,AWS_ACCOUNT,arn:aws:sso:::permissionSet/ssoins-7223d00af1910289/ps-7223081e18fe0738,arn:aws:sso:::instance/ssoins-7223d00af1910289"
}

import {
  to = aws_ssoadmin_account_assignment.tofu["ultary_domains_ghilbut"]
  id = "7488a448-2051-70eb-80b8-106a98d83549,USER,971119963968,AWS_ACCOUNT,arn:aws:sso:::permissionSet/ssoins-7223d00af1910289/ps-7223081e18fe0738,arn:aws:sso:::instance/ssoins-7223d00af1910289"
}
