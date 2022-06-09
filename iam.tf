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

# Make a policy to allow auto joining, auto unsealing and update health state.
data "aws_iam_policy_document" "default" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeTags"
    ]
    resources = ["*"]
  }
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
  statement {
    effect = "Allow"
    actions = [
      "autoscaling:SetInstanceHealth",
    ]
    resources = [aws_autoscaling_group.default.arn]
  }
  statement {
    effect = "Allow"
    actions = [
      "elasticloadbalancing:DeregisterTargets",
    ]
    resources = [aws_lb_target_group.api.arn]
  }
}

# Make a role to allow role assumption.
resource "aws_iam_role" "default" {
  assume_role_policy = data.aws_iam_policy_document.assumerole.json
  description        = "Vault role - ${var.name}"
  name               = var.name
  tags               = local.tags
}

# Link the default role to the join_unseal policy.
resource "aws_iam_role_policy" "default" {
  name   = "${var.name}-vault"
  policy = data.aws_iam_policy_document.default.json
  role   = aws_iam_role.default.id
}

# Make an iam instance profile
resource "aws_iam_instance_profile" "default" {
  name = var.name
  role = aws_iam_role.default.name
  tags = local.tags
}
