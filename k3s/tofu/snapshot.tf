data "terraform_remote_state" "shared_services" {
  backend = "s3"

  config = {
    bucket  = "ghilbut-tfstates"
    encrypt = true
    key     = "platform/aws/shared-services.tfstate"
    region  = "us-east-1"
    assume_role = {
      role_arn = "arn:aws:iam::012646747332:role/tofu-state-readonly"
    }
  }
}

resource "aws_iam_access_key" "cpa_snapshot" {
  user = basename(data.terraform_remote_state.shared_services.outputs.cpa_snapshot_writer_arn)

  lifecycle {
    create_before_destroy = true
    prevent_destroy       = true
  }
}

resource "random_password" "cpa_server_token" {
  length  = 64
  special = false

  lifecycle {
    ignore_changes = [
      length,
      special,
    ]
    prevent_destroy = true
  }
}

locals {
  cpa_snapshot_s3_config = {
    etcd-s3-access-key      = aws_iam_access_key.cpa_snapshot.id
    etcd-s3-bucket          = data.terraform_remote_state.shared_services.outputs.backup_bucket_name
    etcd-s3-folder          = "k3s/cpa"
    etcd-s3-insecure        = "false"
    etcd-s3-region          = "us-east-1"
    etcd-s3-retention       = "28"
    etcd-s3-secret-key      = aws_iam_access_key.cpa_snapshot.secret
    etcd-s3-skip-ssl-verify = "false"
    etcd-s3-timeout         = "5m"
  }
  cpa_snapshot_s3_config_revision = parseint(
    substr(nonsensitive(sha256(jsonencode(local.cpa_snapshot_s3_config))), 0, 7),
    16,
  ) + 1
}

resource "kubernetes_secret_v1" "cpa_snapshot_s3" {
  metadata {
    name      = "k3s-etcd-snapshot-s3-config"
    namespace = "kube-system"
  }

  data_wo          = local.cpa_snapshot_s3_config
  data_wo_revision = local.cpa_snapshot_s3_config_revision
  type             = "etcd.k3s.cattle.io/s3-config-secret"
}
