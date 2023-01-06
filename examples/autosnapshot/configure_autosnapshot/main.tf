resource "vault_raft_snapshot_agent_config" "hourly" {
  aws_s3_bucket     = "vault-snapshots-syzaip"
  aws_s3_enable_kms = true
  aws_s3_region     = "eu-west-1"
  interval_seconds  = 3600 # 1h
  name              = "hourly"
  path_prefix       = "/hourly"
  retain            = 24
  storage_type      = "aws-s3"
}

resource "vault_raft_snapshot_agent_config" "daily" {
  aws_s3_bucket     = "vault-snapshots-syzaip"
  aws_s3_enable_kms = true
  aws_s3_region     = "eu-west-1"
  interval_seconds  = 86400 # 24h
  name              = "daily"
  path_prefix       = "/daily"
  retain            = 7
  storage_type      = "aws-s3"
}

resource "vault_raft_snapshot_agent_config" "weekly" {
  aws_s3_bucket     = "vault-snapshots-syzaip"
  aws_s3_enable_kms = true
  aws_s3_region     = "eu-west-1"
  interval_seconds  = 604800 # 1w
  name              = "weekly"
  path_prefix       = "/weekly"
  retain            = 4
  storage_type      = "aws-s3"
}

resource "vault_raft_snapshot_agent_config" "monthly" {
  aws_s3_bucket     = "vault-snapshots-syzaip"
  aws_s3_enable_kms = true
  aws_s3_region     = "eu-west-1"
  interval_seconds  = 2419200 # 28d
  name              = "monthly"
  path_prefix       = "/monthly"
  retain            = 12
  storage_type      = "aws-s3"
}