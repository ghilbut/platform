data "aws_caller_identity" "management" {}

data "aws_ssoadmin_instances" "this" {}

data "aws_ssoadmin_permission_set" "tofu" {
  instance_arn = one(data.aws_ssoadmin_instances.this.arns)
  name         = "tofu"
}

data "aws_iam_policy_document" "management_tofu_permissions_boundary" {
  statement {
    sid    = "AllowManagementAccountFunctions"
    effect = "Allow"

    actions = [
      "account:*",
      "aws-portal:*",
      "billing:*",
      "budgets:*",
      "ce:*",
      "consolidatedbilling:*",
      "cur:*",
      "freetier:*",
      "identitystore:*",
      "identitystore-auth:*",
      "invoicing:*",
      "organizations:*",
      "payments:*",
      "purchase-orders:*",
      "savingsplans:*",
      "sso:*",
      "sso-directory:*",
      "support:*",
      "tax:*",
      "trustedadvisor:*",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowIdentityCenterServiceRoleCreation"
    effect = "Allow"

    actions = ["iam:CreateServiceLinkedRole"]

    resources = [
      "arn:aws:iam::${data.aws_caller_identity.management.account_id}:role/aws-service-role/sso.amazonaws.com/AWSServiceRoleForSSO",
    ]

    condition {
      test     = "StringLike"
      variable = "iam:AWSServiceName"
      values   = ["sso.amazonaws.com"]
    }
  }

  statement {
    sid    = "AllowIdentityCenterServiceRolePass"
    effect = "Allow"

    actions = ["iam:PassRole"]

    resources = [
      "arn:aws:iam::${data.aws_caller_identity.management.account_id}:role/aws-service-role/sso.amazonaws.com/AWSServiceRoleForSSO",
    ]

    condition {
      test     = "StringLike"
      variable = "iam:PassedToService"
      values   = ["sso.amazonaws.com"]
    }
  }

  statement {
    sid       = "AllowPermissionsBoundaryDiscovery"
    effect    = "Allow"
    actions   = ["iam:ListPolicies"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowPermissionsBoundaryManagement"
    effect = "Allow"

    actions = [
      "iam:CreatePolicy",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicy",
      "iam:DeletePolicyVersion",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListPolicyVersions",
      "iam:TagPolicy",
      "iam:UntagPolicy",
    ]

    resources = [
      "arn:aws:iam::${data.aws_caller_identity.management.account_id}:policy/tofu-permissions-boundary",
    ]
  }

  statement {
    sid    = "DenyAllOtherActions"
    effect = "Deny"

    not_actions = [
      "account:*",
      "aws-portal:*",
      "billing:*",
      "budgets:*",
      "ce:*",
      "consolidatedbilling:*",
      "cur:*",
      "freetier:*",
      "iam:CreatePolicy",
      "iam:CreatePolicyVersion",
      "iam:CreateServiceLinkedRole",
      "iam:DeletePolicy",
      "iam:DeletePolicyVersion",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListPolicies",
      "iam:ListPolicyVersions",
      "iam:PassRole",
      "iam:TagPolicy",
      "iam:UntagPolicy",
      "identitystore:*",
      "identitystore-auth:*",
      "invoicing:*",
      "organizations:*",
      "payments:*",
      "purchase-orders:*",
      "savingsplans:*",
      "sso:*",
      "sso-directory:*",
      "support:*",
      "tax:*",
      "trustedadvisor:*",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "DenyRegionEnablement"
    effect = "Deny"

    actions   = ["account:EnableRegion"]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "member_tofu_permissions_boundary" {
  statement {
    sid       = "AllowAllActions"
    effect    = "Allow"
    actions   = ["*"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "tofu_permissions_boundary" {
  name        = "tofu-permissions-boundary"
  description = "Permissions boundary for the IAM Identity Center tofu permission set."
  policy      = data.aws_iam_policy_document.management_tofu_permissions_boundary.json
}

resource "aws_iam_policy" "tofu_permissions_boundary_platform" {
  provider = aws.platform

  name        = aws_iam_policy.tofu_permissions_boundary.name
  description = aws_iam_policy.tofu_permissions_boundary.description
  policy      = data.aws_iam_policy_document.member_tofu_permissions_boundary.json
}

resource "aws_iam_policy" "tofu_permissions_boundary_ultary" {
  provider = aws.ultary

  name        = aws_iam_policy.tofu_permissions_boundary.name
  description = aws_iam_policy.tofu_permissions_boundary.description
  policy      = data.aws_iam_policy_document.member_tofu_permissions_boundary.json
}

resource "aws_ssoadmin_permissions_boundary_attachment" "tofu" {
  instance_arn       = one(data.aws_ssoadmin_instances.this.arns)
  permission_set_arn = data.aws_ssoadmin_permission_set.tofu.arn

  permissions_boundary {
    customer_managed_policy_reference {
      name = aws_iam_policy.tofu_permissions_boundary.name
      path = "/"
    }
  }

  depends_on = [
    aws_iam_policy.tofu_permissions_boundary,
    aws_iam_policy.tofu_permissions_boundary_platform,
    aws_iam_policy.tofu_permissions_boundary_ultary,
  ]
}

resource "aws_account_region" "opt_in" {
  for_each = toset([
    "af-south-1",
    "ap-east-1",
    "ap-east-2",
    "ap-south-2",
    "ap-southeast-3",
    "ap-southeast-4",
    "ap-southeast-5",
    "ap-southeast-6",
    "ap-southeast-7",
    "ca-west-1",
    "eu-central-2",
    "eu-south-1",
    "eu-south-2",
    "il-central-1",
    "me-central-1",
    "me-south-1",
    "mx-central-1",
  ])

  region_name = each.value
  enabled     = false
}
