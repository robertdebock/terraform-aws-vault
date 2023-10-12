# Cloudwatch logs feature
resource "aws_cloudwatch_log_group" "cloudinitlog" {
  count             = var.vault_enable_cloudwatch ? 1 : 0
  name              = "cloudinitlog-${var.vault_name}-${random_string.default.result}" # Needs to match the log-group name configured for the Cloudwatch-agent in cloudwatch.sh
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "vaultlog" {
  count             = var.vault_enable_cloudwatch ? 1 : 0
  name              = "vaultlog-${var.vault_name}-${random_string.default.result}" # Needs to match the log-group name configured for the Cloudwatch-agent in cloudwatch.sh
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "lambda" {
  count             = var.vault_enable_cloudwatch ? 1 : 0
  name              = "/aws/lambda/${aws_lambda_function.CloudWatchAutoAlarms[0].function_name}"
  retention_in_days = 7
}

# Cloudwatch metrics dashboard feature
resource "aws_cloudwatch_dashboard" "default" {
  count = var.vault_enable_cloudwatch ? 1 : 0
  dashboard_body = (templatefile("${path.module}/templates/cloudwatch_dashboard.json.tpl", {
    aws_region                 = "${data.aws_region.default.name}",
    asg_name                   = "${aws_autoscaling_group.default.name}",
    vault_cloudwatch_namespace = "${local.vault_cloudwatch_namespace}",
    vault_data_path            = "${var.vault_data_path}",
    amount                     = local.amount,
    aws_lb_target_group_name   = "${aws_lb_target_group.api.name}",
    aws_lb_target_group_arn    = "${aws_lb_target_group.api.arn_suffix}",
    aws_lb_api_arn             = "${aws_lb.api.arn_suffix}",
  }))
  dashboard_name = "vault-${var.vault_name}-${random_string.default.result}"
}

# Cloudwatch alerting feature
resource "aws_sns_topic" "alerts" {
  count           = var.vault_enable_cloudwatch ? 1 : 0
  name_prefix     = "CloudWatchAutoAlarmsSNSTopic-"
  delivery_policy = file("${path.module}/templates/aws_sns_topic_alerts_delivery_policy.json")
}

resource "aws_lambda_function" "CloudWatchAutoAlarms" {
  count            = var.vault_enable_cloudwatch ? 1 : 0
  filename         = "${path.module}/scripts/cloudwatch_alarms/amazon-cloudwatch-auto-alarms.zip"
  function_name    = "CloudWatchAutoAlarms-${random_string.default.result}"
  role             = aws_iam_role.lambda[0].arn
  handler          = "cw_auto_alarms.lambda_handler"
  source_code_hash = filebase64sha256("${path.module}/scripts/cloudwatch_alarms/amazon-cloudwatch-auto-alarms.zip")
  runtime          = "python3.8"
  memory_size      = 128
  timeout          = 10

  environment {
    variables = {
      ALARM_TAG                        = "Create_Auto_Alarms"
      CREATE_DEFAULT_ALARMS            = true
      CLOUDWATCH_NAMESPACE             = local.vault_cloudwatch_namespace
      ALARM_MEMORY_HIGH_THRESHOLD      = 80
      ALARM_DISK_PERCENT_LOW_THRESHOLD = 20
      CLOUDWATCH_APPEND_DIMENSIONS     = "InstanceId, AutoScalingGroupName"
      ALARM_LAMBDA_ERROR_THRESHOLD     = 0
      ALARM_LAMBDA_THROTTLE_THRESHOLD  = 0
      DEFAULT_ALARM_SNS_TOPIC_ARN      = aws_sns_topic.alerts[0].arn
      VAULT_PATH                       = var.vault_data_path
    }
  }
}

resource "time_sleep" "cloudwatch_alarm_cleanup_timer" {
  count      = var.vault_enable_cloudwatch ? 1 : 0
  depends_on = [
    aws_lambda_function.CloudWatchAutoAlarms,
    aws_cloudwatch_event_target.ec2_alarms,
    aws_cloudwatch_event_rule.ec2_alarms,
    aws_lambda_permission.ec2_alarms,
    aws_cloudwatch_event_target.lambda,
    aws_cloudwatch_event_rule.lambda,
    aws_lambda_permission.lambda_cloudwatch,
    aws_iam_role_policy.lambda[0],
    aws_cloudwatch_log_group.lambda,
    aws_iam_role.lambda[0]
  ]

  destroy_duration = "40s" # The lambda function needs some time to trigger and clean up the alarms.
}

resource "aws_cloudwatch_event_rule" "ec2_alarms" {
  count         = var.vault_enable_cloudwatch ? 1 : 0
  name_prefix   = "Initiate-CloudWatchAutoAlarmsEC2-"
  description   = "Creates CloudWatch alarms on instance start via Lambda CloudWatchAutoAlarms and deletes them on instance termination."
  event_pattern = file("${path.module}/templates/cloudwatch_ec2_alarms_event_pattern.json")
}

resource "aws_cloudwatch_event_target" "ec2_alarms" {
  count     = var.vault_enable_cloudwatch ? 1 : 0
  rule      = aws_cloudwatch_event_rule.ec2_alarms[0].name
  target_id = "ec2_alarms_event_target"
  arn       = aws_lambda_function.CloudWatchAutoAlarms[0].arn
}

resource "aws_lambda_permission" "ec2_alarms" {
  count         = var.vault_enable_cloudwatch ? 1 : 0
  statement_id  = "AllowCloudWatchAutoAlarmCloudwatchEventEC2"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.CloudWatchAutoAlarms[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ec2_alarms[0].arn
}

resource "aws_cloudwatch_event_rule" "lambda" {
  count         = var.vault_enable_cloudwatch ? 1 : 0
  name          = "Initiate-CloudWatchAutoAlarmsLambda-${random_string.default.result}"
  description   = "Creates CloudWatch alarms on for lambda functions with the CloudWatchAutoAlarms activation tag"
  event_pattern = file("${path.module}/templates/cloudwatch_lambda_event_pattern.json")
}

resource "aws_cloudwatch_event_target" "lambda" {
  count     = var.vault_enable_cloudwatch ? 1 : 0
  rule      = aws_cloudwatch_event_rule.lambda[0].name
  target_id = "alarms_event_target"
  arn       = aws_lambda_function.CloudWatchAutoAlarms[0].arn
}

resource "aws_lambda_permission" "lambda_cloudwatch" {
  count         = var.vault_enable_cloudwatch ? 1 : 0
  statement_id  = "AllowCloudWatchAutoAlarmCloudwatchEventLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.CloudWatchAutoAlarms[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda[0].arn
}
