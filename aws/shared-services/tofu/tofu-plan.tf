resource "aws_iam_role" "tofu_plan" {
  name                 = "tofu-plan"
  description          = "Read-only OpenTofu execution role for the SharedServices account."
  max_session_duration = 14400

  lifecycle {
    create_before_destroy = true
  }

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowIdentityCenterPermissionSet"
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::${local.shared_services_account_id}:root"
      }
      Action = "sts:AssumeRole"
      Condition = {
        ArnLike = {
          "aws:PrincipalArn" = "arn:aws:iam::${local.shared_services_account_id}:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_TofuPlanForWorkloads_*"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "tofu_plan" {
  name = "tofu-plan-read-only"
  role = aws_iam_role.tofu_plan.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "ReadCertificates"
        Action = [
          "acm:DescribeCertificate",
          "acm:ListTagsForCertificate",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:acm:us-east-1:${local.shared_services_account_id}:certificate/*"
      },
      {
        Sid = "ReadCloudFront"
        Action = [
          "cloudfront:DescribeFunction",
          "cloudfront:GetDistribution",
          "cloudfront:GetDistributionConfig",
          "cloudfront:GetFunction",
          "cloudfront:GetOriginAccessControl",
          "cloudfront:ListTagsForResource",
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:cloudfront::${local.shared_services_account_id}:distribution/*",
          "arn:aws:cloudfront::${local.shared_services_account_id}:function/*",
          "arn:aws:cloudfront::${local.shared_services_account_id}:origin-access-control/*",
        ]
      },
      {
        Sid = "ReadRoles"
        Action = [
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole",
          "iam:ListRolePolicies",
          "iam:ListRoleTags",
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:iam::${local.shared_services_account_id}:role/cdn-platform-github-actions",
          "arn:aws:iam::${local.shared_services_account_id}:role/cdn-platform-lambda",
          "arn:aws:iam::${local.shared_services_account_id}:role/tofu-apply",
          "arn:aws:iam::${local.shared_services_account_id}:role/tofu-plan",
        ]
      },
      {
        Sid = "ReadOpenIDConnectProviders"
        Action = [
          "iam:GetOpenIDConnectProvider",
          "iam:ListOpenIDConnectProviderTags",
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:iam::${local.shared_services_account_id}:oidc-provider/oidc.k3s.ghilbut.com/cpa",
          "arn:aws:iam::${local.shared_services_account_id}:oidc-provider/token.actions.githubusercontent.com",
        ]
      },
      {
        Sid = "ReadLambda"
        Action = [
          "lambda:GetFunction",
          "lambda:GetFunctionCodeSigningConfig",
          "lambda:GetFunctionConfiguration",
          "lambda:GetPolicy",
          "lambda:ListTags",
          "lambda:ListVersionsByFunction",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:lambda:us-east-1:${local.shared_services_account_id}:function:cdn-platform-origin-request*"
      },
      {
        Sid = "ReadManagedBuckets"
        Action = [
          "s3:GetAccelerateConfiguration",
          "s3:GetBucketAcl",
          "s3:GetBucketCORS",
          "s3:GetBucketLocation",
          "s3:GetBucketLogging",
          "s3:GetBucketObjectLockConfiguration",
          "s3:GetBucketOwnershipControls",
          "s3:GetBucketPolicy",
          "s3:GetBucketPolicyStatus",
          "s3:GetBucketPublicAccessBlock",
          "s3:GetBucketRequestPayment",
          "s3:GetBucketTagging",
          "s3:GetBucketVersioning",
          "s3:GetBucketWebsite",
          "s3:GetEncryptionConfiguration",
          "s3:GetLifecycleConfiguration",
          "s3:GetReplicationConfiguration",
          "s3:ListBucket",
          "s3:ListTagsForResource",
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::ghilbut-cdn-platform",
          "arn:aws:s3:::ghilbut-tfstates",
        ]
      },
      {
        Sid = "ReadManagedObjects"
        Action = [
          "s3:GetObject",
          "s3:GetObjectAttributes",
          "s3:GetObjectTagging",
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::ghilbut-cdn-platform/404.html",
          "arn:aws:s3:::ghilbut-cdn-platform/503.html",
          "arn:aws:s3:::ghilbut-cdn-platform/lambda.zip",
          "arn:aws:s3:::ghilbut-cdn-platform/oidc.k3s.ghilbut.com/cpa/.well-known/openid-configuration",
          "arn:aws:s3:::ghilbut-cdn-platform/oidc.k3s.ghilbut.com/cpa/openid/v1/jwks",
        ]
      },
      {
        Sid = "ReadResourceTags"
        Action = [
          "tag:GetResources",
          "tag:GetTagKeys",
          "tag:GetTagValues",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Sid      = "ReadCallerIdentity"
        Action   = "sts:GetCallerIdentity"
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}
