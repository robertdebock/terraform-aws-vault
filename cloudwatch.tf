resource "aws_cloudwatch_dashboard" "default" {
  count          = var.vault_enable_cloudwatch ? 1 : 0
  dashboard_name = var.vault_name
  dashboard_body = jsonencode(file("${path.module}/dashboard.json"))
}
