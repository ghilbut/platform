locals {
  developer_central_administration_denied_actions = [
    "account:*",
    "artifact:*",
    "aws-marketplace:*",
    "aws-portal:*",
    "billing:*",
    "budgets:*",
    "ce:*",
    "consolidatedbilling:*",
    "cost-optimization-hub:*",
    "cur:*",
    "identitystore:*",
    "identitystore-auth:*",
    "identity-sync:*",
    "invoicing:*",
    "organizations:*",
    "observabilityadmin:*ForOrganization",
    "payments:*",
    "purchase-orders:*",
    "sso:*",
    "sso-directory:*",
    "support:*",
    "trustedadvisor:*",
    "uxc:*",
  ]

  developer_protected_value_denied_actions = [
    "appconfig:GetConfiguration",
    "appconfig:GetLatestConfiguration",
    "appconfig:StartConfigurationSession",
    "athena:GetQueryResults",
    "autoscaling:DescribeLaunchConfigurations",
    "backup:*LegalHold*",
    "cassandra:Select",
    "cloudtrail:LookupEvents",
    "cognito-identity:GetCredentialsForIdentity",
    "cognito-identity:GetOpenIdToken",
    "cognito-identity:GetOpenIdTokenForDeveloperIdentity",
    "cognito-identity:ListIdentities",
    "cognito-idp:AdminGetUser",
    "cognito-idp:AdminListGroupsForUser",
    "cognito-idp:ListUsers",
    "cognito-idp:ListUsersInGroup",
    "cognito-sync:*",
    "cloudfront:GetFunction",
    "connect:*",
    "devicefarm:ListArtifacts",
    "dynamodb:BatchGetItem",
    "dynamodb:GetItem",
    "dynamodb:PartiQLSelect",
    "dynamodb:Query",
    "dynamodb:Scan",
    "ec2:DescribeInstanceAttribute",
    "ecr:BatchGetImage",
    "ecr:GetAuthorizationToken",
    "ecr:GetDownloadUrlForLayer",
    "es:ESHttpGet",
    "glacier:GetJobOutput",
    "iam:GetCredentialReport",
    "iam:GetLoginProfile",
    "iam:GetMFADevice",
    "iam:GetSSHPublicKey",
    "iam:ListAccessKeys",
    "iam:ListMFADevices",
    "iam:ListServiceSpecificCredentials",
    "iam:ListSigningCertificates",
    "iam:ListSSHPublicKeys",
    "iam:ListVirtualMFADevices",
    "iot:Connect",
    "iot:Receive",
    "iot:Subscribe",
    "kinesis:GetRecords",
    "kinesis:SubscribeToShard",
    "kms:Decrypt",
    "kms:DeriveSharedSecret",
    "kms:GenerateDataKey*",
    "kms:GenerateMac",
    "kms:ReEncrypt*",
    "kms:Sign",
    "lambda:GetFunction",
    "lambda:GetLayerVersion",
    "lex:GetUtterancesView",
    "mobiletargeting:*",
    "profile:*",
    "rds-data:BatchExecuteStatement",
    "rds-data:BeginTransaction",
    "rds-data:ExecuteStatement",
    "redshift-data:BatchExecuteStatement",
    "redshift-data:ExecuteStatement",
    "redshift-data:GetStatementResult",
    "redshift:ViewQueriesInConsole",
    "rolesanywhere:ListSubjects",
    "route53domains:GetDomainDetail",
    "route53domains:RetrieveDomainAuthCode",
    "rum:GetAppMonitorData",
    "s3:GetObject*",
    "s3-object-lambda:GetObject*",
    "secretsmanager:BatchGetSecretValue",
    "secretsmanager:GetSecretValue",
    "ses:ListContacts",
    "ses:ListEmailIdentities",
    "ses:ListIdentities",
    "ses:ListSuppressedDestinations",
    "ses:ListVerifiedEmailAddresses",
    "sns:GetEndpointAttributes",
    "sns:GetSubscriptionAttributes",
    "sns:ListEndpointsByPlatformApplication",
    "sns:ListPhoneNumbersOptedOut",
    "sns:ListSMSSandboxPhoneNumbers",
    "sns:ListSubscriptions",
    "sns:ListSubscriptionsByTopic",
    "sqs:ReceiveMessage",
    "ssm:GetCommandInvocation",
    "ssm:GetParameter*",
    "sts:AssumeRole",
    "synthetics:GetCanary",
    "timestream:Select",
    "workdocs:*",
    "workmail:*",
    "workspaces:*",
  ]

  developer_configuration_read_actions = [
    "acm:DescribeCertificate",
    "acm:ListTagsForCertificate",
    "access-analyzer:CheckAccessNotGranted",
    "access-analyzer:CheckNoNewAccess",
    "access-analyzer:Get*",
    "access-analyzer:List*",
    "access-analyzer:ValidatePolicy",
    "cloudfront:Get*",
    "cloudfront:DescribeFunction",
    "cloudtrail:GetEventSelectors",
    "cloudtrail:GetInsightSelectors",
    "cloudtrail:GetTrail",
    "cloudtrail:GetTrailStatus",
    "codebuild:BatchGetBuilds",
    "codebuild:BatchGetProjects",
    "codebuild:BatchGetReportGroups",
    "codebuild:BatchGetReports",
    "codepipeline:GetPipeline",
    "codepipeline:GetPipelineExecution",
    "codepipeline:GetPipelineState",
    "codepipeline:ListActionExecutions",
    "codepipeline:ListPipelineExecutions",
    "codepipeline:ListTagsForResource",
    "config:BatchGetAggregateResourceConfig",
    "config:BatchGetResourceConfig",
    "config:Get*",
    "config:SelectAggregateResourceConfig",
    "config:SelectResourceConfig",
    "ecr:BatchGetRepositoryScanningConfiguration",
    "ecr:DescribeImageScanFindings",
    "ecr:DescribeImages",
    "ecr:GetLifecyclePolicy",
    "ecr:GetLifecyclePolicyPreview",
    "ecr:GetRegistryPolicy",
    "ecr:GetRegistryScanningConfiguration",
    "ecr:GetRepositoryPolicy",
    "ecr:ListTagsForResource",
    "elasticloadbalancing:Describe*",
    "health:Describe*",
    "iam:GetAccountAuthorizationDetails",
    "iam:GetAccountPasswordPolicy",
    "iam:GetContextKeysForCustomPolicy",
    "iam:GetContextKeysForPrincipalPolicy",
    "iam:GetGroup",
    "iam:GetGroupPolicy",
    "iam:GetInstanceProfile",
    "iam:GetOpenIDConnectProvider",
    "iam:GetPolicy",
    "iam:GetPolicyVersion",
    "iam:GetRole",
    "iam:GetRolePolicy",
    "iam:GetSAMLProvider",
    "iam:GetServerCertificate",
    "iam:GetServiceLinkedRoleDeletionStatus",
    "iam:GetUser",
    "iam:GetUserPolicy",
    "iam:SimulateCustomPolicy",
    "iam:SimulatePrincipalPolicy",
    "kms:DescribeKey",
    "kms:GetKeyPolicy",
    "kms:GetKeyRotationStatus",
    "kms:ListAliases",
    "kms:ListGrants",
    "kms:ListKeyPolicies",
    "kms:ListRetirableGrants",
    "lambda:GetAccountSettings",
    "lambda:GetAlias",
    "lambda:GetCodeSigningConfig",
    "lambda:GetEventSourceMapping",
    "lambda:GetFunctionCodeSigningConfig",
    "lambda:GetFunctionConcurrency",
    "lambda:GetFunctionConfiguration",
    "lambda:GetFunctionEventInvokeConfig",
    "lambda:GetFunctionRecursionConfig",
    "lambda:GetFunctionUrlConfig",
    "lambda:GetPolicy",
    "lambda:GetProvisionedConcurrencyConfig",
    "lambda:GetRuntimeManagementConfig",
    "s3:GetAccessPoint*",
    "s3:GetAccountPublicAccessBlock",
    "s3:GetBucket*",
    "s3:GetEncryptionConfiguration",
    "s3:GetLifecycleConfiguration",
    "s3:GetReplicationConfiguration",
    "s3:GetStorageLensConfiguration",
    "servicequotas:GetAWSDefaultServiceQuota",
    "servicequotas:GetServiceQuota",
    "servicequotas:List*",
    "tag:GetResources",
    "tag:GetTagKeys",
    "tag:GetTagValues",
    "waf:Get*",
    "waf-regional:Get*",
    "wafv2:Describe*",
    "wafv2:Get*",
  ]

  developer_security_read_actions = [
    "guardduty:Get*",
    "guardduty:List*",
    "inspector2:BatchGet*",
    "inspector2:Get*",
    "inspector2:List*",
    "securityhub:BatchGet*",
    "securityhub:Describe*",
    "securityhub:Get*",
    "securityhub:List*",
  ]

  developer_secret_inventory_read_actions = [
    "secretsmanager:DescribeSecret",
    "secretsmanager:GetResourcePolicy",
    "secretsmanager:ListSecrets",
    "secretsmanager:ListSecretVersionIds",
    "ssm:DescribeParameters",
    "ssm:ListTagsForResource",
  ]

  developer_registered_domain_read_actions = [
    "route53domains:CheckDomainAvailability",
    "route53domains:CheckDomainTransferability",
    "route53domains:GetContactReachabilityStatus",
    "route53domains:GetOperationDetail",
    "route53domains:ListDomains",
    "route53domains:ListOperations",
    "route53domains:ListPrices",
    "route53domains:ListTagsForDomain",
  ]

  developer_protected_bucket_arns = [
    "arn:aws:s3:::ghilbut-backups",
    "arn:aws:s3:::ghilbut-tfstates",
    "arn:aws:s3:::ghilbut-tfstates-v2",
  ]
}

resource "aws_identitystore_group" "developers" {
  display_name      = "Developers"
  identity_store_id = local.identity_store_id
}

resource "aws_identitystore_group_membership" "developers_ghilbut" {
  group_id          = aws_identitystore_group.developers.group_id
  identity_store_id = local.identity_store_id
  member_id         = local.ghilbut_user_id
}

module "developers" {
  source = "./modules/permission-set"

  instance_arn = local.instance_arn
  name         = "Developers"
  description  = "Read-only AWS visibility for developers without protected values."
  managed_policy_arns = toset([
    "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess",
    "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess",
  ])
  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyCentralAdministration"
        Effect   = "Deny"
        Action   = local.developer_central_administration_denied_actions
        Resource = "*"
      },
      {
        Sid      = "DenyProtectedValues"
        Effect   = "Deny"
        Action   = local.developer_protected_value_denied_actions
        Resource = "*"
      },
      {
        Sid      = "DenyApiGatewayApiKeyValues"
        Effect   = "Deny"
        Action   = "apigateway:GET"
        Resource = "arn:aws:apigateway:*::/apikeys*"
      },
      {
        Sid    = "DenyProtectedObjectInventory"
        Effect = "Deny"
        Action = [
          "s3:ListBucket",
          "s3:ListBucketVersions",
        ]
        Resource = local.developer_protected_bucket_arns
      },
      {
        Sid      = "AllowConfigurationRead"
        Effect   = "Allow"
        Action   = local.developer_configuration_read_actions
        Resource = "*"
      },
      {
        Sid      = "AllowOperationalSecurityRead"
        Effect   = "Allow"
        Action   = local.developer_security_read_actions
        Resource = "*"
      },
      {
        Sid      = "AllowSecretInventoryRead"
        Effect   = "Allow"
        Action   = local.developer_secret_inventory_read_actions
        Resource = "*"
      },
      {
        Sid      = "AllowRegisteredDomainOperations"
        Effect   = "Allow"
        Action   = local.developer_registered_domain_read_actions
        Resource = "*"
      },
      {
        Sid      = "AllowCallerIdentity"
        Effect   = "Allow"
        Action   = "sts:GetCallerIdentity"
        Resource = "*"
      },
    ]
  })
  account_assignments = merge(
    {
      for name, account in local.workload_accounts : name => {
        account_id     = account.account_id
        principal_id   = aws_identitystore_group.developers.group_id
        principal_type = "GROUP"
      }
    },
    {
      domains = {
        account_id     = local.domains_account_id
        principal_id   = aws_identitystore_group.developers.group_id
        principal_type = "GROUP"
      }
    },
  )
}
