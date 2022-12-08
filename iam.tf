# Make a policy to allow role assumption.
data "aws_iam_policy_document" "assumerole" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
  }
}

# Make a policy to allow auto joining.
data "aws_iam_policy_document" "autojoin" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeTags"
    ]
    resources = ["*"]
  }
}

# Make a policy to allow auto unsealing.
data "aws_iam_policy_document" "autounseal" {
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
    ]
    resources = [
      local.aws_kms_key_arn
    ]
  }
}

# Make a policy to allow setting ASG health state.
data "aws_iam_policy_document" "sethealth" {
  statement {
    effect = "Allow"
    actions = [
      "autoscaling:SetInstanceHealth",
    ]
    resources = [aws_autoscaling_group.default.arn]
  }
}

# Make a policy to allow instances to deregister from a target group.
data "aws_iam_policy_document" "deregister" {
  statement {
    effect = "Allow"
    actions = [
      "elasticloadbalancing:DeregisterTargets",
    ]
    resources = [aws_lb_target_group.api.arn]
  }
}

# Make a policy to allow snapshots to S3.
data "aws_iam_policy_document" "autosnapshot" {
  count = var.vault_aws_s3_snapshots_bucket_name == "" ? 0 : 1
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::${var.vault_aws_s3_snapshots_bucket_name}/*.snap",
      "arn:aws:s3:::${var.vault_aws_s3_snapshots_bucket_name}/*/*.snap"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucketVersions",
      "s3:ListBucket"
    ]
    resources = ["arn:aws:s3:::${var.vault_aws_s3_snapshots_bucket_name}"]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${var.vault_aws_s3_snapshots_bucket_name}",
      "arn:aws:s3:::${var.vault_aws_s3_snapshots_bucket_name}/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey"
    ]
    resources = ["*"]
  }
}

# Make a policy to allow downloading vault scripts from S3.
data "aws_iam_policy_document" "scripts" {
  count = var.vault_enable_cloudwatch || var.vault_audit_device? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "${aws_s3_bucket.default.arn}/*.sh"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "${aws_s3_bucket.default.arn}"
    ]
  }
}

# Make a policy to allow downloading custom scripts from S3.
data "aws_iam_policy_document" "custom_scripts" {
  count = var.vault_custom_script_s3_url == "" ? 0 : 1
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "${var.vault_custom_script_s3_bucket_arn}/*.sh"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "${var.vault_custom_script_s3_bucket_arn}"
    ]
  }
}

# Make a role to allow role assumption.
resource "aws_iam_role" "default" {
  assume_role_policy = data.aws_iam_policy_document.assumerole.json
  description        = "Vault role - ${var.vault_name}"
  name               = local.name
  tags               = local.tags
}

# Link the autojoin policy to the default role.
resource "aws_iam_role_policy" "autojoin" {
  name   = "${var.vault_name}-vault-autojoin"
  policy = data.aws_iam_policy_document.autojoin.json
  role   = aws_iam_role.default.id
}

# Link the auto unseal policy to the default role.
resource "aws_iam_role_policy" "autounseal" {
  name   = "${var.vault_name}-vault-autounseal"
  policy = data.aws_iam_policy_document.autounseal.json
  role   = aws_iam_role.default.id
}

# Link the set health policy to the default role.
resource "aws_iam_role_policy" "sethealth" {
  name   = "${var.vault_name}-vault-sethealth"
  policy = data.aws_iam_policy_document.sethealth.json
  role   = aws_iam_role.default.id
}

# Link the deregister policy to the default role.
resource "aws_iam_role_policy" "deregister" {
  name   = "${var.vault_name}-vault-deregister"
  policy = data.aws_iam_policy_document.deregister.json
  role   = aws_iam_role.default.id
}

# Link the autosnapshot policy to the default role.
resource "aws_iam_role_policy" "autosnapshot" {
  count  = var.vault_aws_s3_snapshots_bucket_name == "" ? 0 : 1
  name   = "${var.vault_name}-vault-autosnapshot"
  policy = data.aws_iam_policy_document.autosnapshot[0].json
  role   = aws_iam_role.default.id
}

# Link the scripts policy to the default role.
resource "aws_iam_role_policy" "scripts" {
  count  = var.vault_enable_cloudwatch || var.vault_audit_device ? 1 : 0
  name   = "${var.vault_name}-vault-scripts"
  policy = data.aws_iam_policy_document.scripts[0].json
  role   = aws_iam_role.default.id
}

# Link the custom scripts policy to the default role.
resource "aws_iam_role_policy" "custom_scripts" {
  count  = var.vault_custom_script_s3_url == "" ? 0 : 1
  name   = "${var.vault_name}-vault-custom-scripts"
  policy = data.aws_iam_policy_document.custom_scripts[0].json
  role   = aws_iam_role.default.id
}

# Link the AWS managed policy "CloudWatchAgentServerPolicy" to the default role. 
resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  count      = var.vault_enable_cloudwatch ? 1 : 0
  role       = aws_iam_role.default.id
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Make an iam instance profile
resource "aws_iam_instance_profile" "default" {
  name = local.name
  role = aws_iam_role.default.name
  tags = local.tags
}

# Create a role with attached policies for Lambda function that automatically creates Cloudwatch alarms for newly created ASG instances
resource "aws_iam_role" "lambda" {
  count              = var.vault_enable_cloudwatch ? 1 : 0
  name               = "${var.vault_name}-lambda-${random_string.default.result}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "lambda" {
  count  = var.vault_enable_cloudwatch ? 1 : 0
  name   = "${var.vault_name}-vault-lambda"
  policy = data.aws_iam_policy_document.lambda[0].json
  role   = aws_iam_role.lambda[0].id
}

data "aws_iam_policy_document" "lambda" {
  count  = var.vault_enable_cloudwatch ? 1 : 0
  statement {
    effect  = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups"
    ]
    resources = [
      # TODO should be --> Resource: !Sub "arn:${AWS::Partition}:logs:${AWS::Region}:${AWS::AccountId}:log-group:*"
      "*"
    ]
  }
  statement {
    effect  = "Allow"
    actions = [
      "logs:PutLogEvents"
    ]
    resources = [
      # TODO should be --> Resource: !Sub "arn:${AWS::Partition}:logs:${AWS::Region}:${AWS::AccountId}:log-group:*:log-stream:*"
      "*"
    ]
  }
  statement {
    effect  = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeImages"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    effect  = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeImages"
    ]
    resources = [
      # TODO should be --> Resource: !Sub "arn:${AWS::Partition}:ec2:${AWS::Region}:${AWS::AccountId}:instance/*"
      "*"
    ]
  }
  statement {
    effect  = "Allow"
    actions = [
      "cloudwatch:DescribeAlarms",
      "cloudwatch:DeleteAlarms",
      "cloudwatch:PutMetricAlarm"
    ]
    resources = [
      # TODO should be --> Resource:  !Sub "arn:${AWS::Partition}:cloudwatch:${AWS::Region}:${AWS::AccountId}:alarm:AutoAlarm-*"
      "*"
    ]
  }
  statement {
    effect  = "Allow"
    actions = [
      "cloudwatch:DescribeAlarms"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    effect  = "Allow"
    actions = [
      "ec2:CreateTags"
    ]
    resources = [
      # TODO should be --> Resource: !Sub "arn:${AWS::Partition}:ec2:${AWS::Region}:${AWS::AccountId}:instance/*"
      "*"
    ]
  }
}

