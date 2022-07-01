resource "vault_raft_snapshot_agent_config" "hourly" {
  name              = "hourly"
  interval_seconds  = 3600 # 1h
  retain            = 24
  path_prefix       = "/hourly"
  storage_type      = "aws-s3"
  aws_s3_bucket     = "vault-snapshots-syzaip"
  aws_s3_region     = "eu-west-1"
  aws_s3_enable_kms = true
}

resource "vault_raft_snapshot_agent_config" "daily" {
  name              = "daily"
  interval_seconds  = 86400 # 24h
  retain            = 7
  path_prefix       = "/daily"
  storage_type      = "aws-s3"
  aws_s3_bucket     = "vault-snapshots-syzaip"
  aws_s3_region     = "eu-west-1"
  aws_s3_enable_kms = true
}

resource "vault_raft_snapshot_agent_config" "weekly" {
  name              = "weekly"
  interval_seconds  = 604800 # 1w
  retain            = 4
  path_prefix       = "/weekly"
  storage_type      = "aws-s3"
  aws_s3_bucket     = "vault-snapshots-syzaip"
  aws_s3_region     = "eu-west-1"
  aws_s3_enable_kms = true
}

resource "vault_raft_snapshot_agent_config" "monthly" {
  name              = "monthly"
  interval_seconds  = 2419200 # 28d
  retain            = 12
  path_prefix       = "/monthly"
  storage_type      = "aws-s3"
  aws_s3_bucket     = "vault-snapshots-syzaip"
  aws_s3_region     = "eu-west-1"
  aws_s3_enable_kms = true
}