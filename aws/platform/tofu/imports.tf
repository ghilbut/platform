import {
  to = aws_s3_bucket.state["primary"]
  id = "ghilbut-tfstates"
}

import {
  to = aws_s3_bucket_ownership_controls.state["primary"]
  id = "ghilbut-tfstates"
}

import {
  to = aws_s3_bucket_policy.state["primary"]
  id = "ghilbut-tfstates"
}

import {
  to = aws_s3_bucket_public_access_block.state["primary"]
  id = "ghilbut-tfstates"
}

import {
  to = aws_s3_bucket_server_side_encryption_configuration.state["primary"]
  id = "ghilbut-tfstates"
}

import {
  to = aws_s3_bucket_versioning.state["primary"]
  id = "ghilbut-tfstates"
}

import {
  to = aws_iam_openid_connect_provider.cpa
  id = "arn:aws:iam::012646747332:oidc-provider/oidc.k3s.ghilbut.com/cpa"
}

import {
  to = aws_iam_role.tofu_apply
  id = "tofu-apply"
}

import {
  to = aws_iam_role_policy.tofu_apply
  id = "tofu-apply:tofu-apply-inline"
}

import {
  to = aws_iam_role_policy_attachment.tofu_apply["arn:aws:iam::aws:policy/IAMFullAccess"]
  id = "tofu-apply/arn:aws:iam::aws:policy/IAMFullAccess"
}

import {
  to = aws_iam_role_policy_attachment.tofu_apply["arn:aws:iam::aws:policy/PowerUserAccess"]
  id = "tofu-apply/arn:aws:iam::aws:policy/PowerUserAccess"
}
