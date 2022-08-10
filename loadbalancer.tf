# Create a placement group that spreads.
resource "aws_placement_group" "default" {
  name     = var.name
  strategy = "spread"
  tags     = local.tags
}

# Add a load balancer for the API/UI.
resource "aws_lb" "api" {
  name            = "${var.name}-api-${random_string.default.result}"
  internal        = var.aws_lb_internal
  security_groups = [aws_security_group.public.id, aws_security_group.private.id]
  subnets         = local.public_subnet_ids
  tags            = local.api_tags
}

# Add a load balancer for replication.
resource "aws_lb" "replication" {
  count              = var.vault_replication ? 1 : 0
  load_balancer_type = "network"
  name               = "${var.name}-replication"
  subnets            = local.public_subnet_ids
  tags               = local.replication_tags
}

# Create a load balancer target group for the API/UI.
resource "aws_lb_target_group" "api" {
  deregistration_delay = 10
  name_prefix          = "${var.name}-"
  port                 = 8200
  protocol             = "HTTPS"
  tags                 = local.api_tags
  vpc_id               = local.vpc_id
  health_check {
    interval = 5
    # See TELEMETRY.md for an explanation.
    matcher  = var.telemetry && !var.telemetry_unauthenticated_metrics_access ? "200,472,473" : "200,429,472,473"
    path     = "/v1/sys/health"
    protocol = "HTTPS"
    timeout  = 2
  }
}

# Create a load balancer target group.
resource "aws_lb_target_group" "replication" {
  count       = var.vault_replication ? 1 : 0
  name_prefix = "${var.name}-"
  port        = 8201
  protocol    = "TCP"
  tags        = local.replication_tags
  vpc_id      = local.vpc_id
}

# TODO: Add a listener on :80/tcp that redirects to `var.api_port`. (Don't forget about the security groups.)

# Add a API listener to the loadbalancer.
resource "aws_lb_listener" "api" {
  certificate_arn   = var.certificate_arn
  load_balancer_arn = aws_lb.api.arn
  port              = var.api_port
  protocol          = "HTTPS"
  tags              = local.api_tags
  default_action {
    target_group_arn = aws_lb_target_group.api.arn
    type             = "forward"
  }
}

# Add a replication listener to the loadbalancer.
resource "aws_lb_listener" "replication" {
  count             = var.vault_replication ? 1 : 0
  load_balancer_arn = aws_lb.replication[0].arn
  port              = var.replication_port
  protocol          = "TCP"
  tags              = local.replication_tags
  default_action {
    target_group_arn = aws_lb_target_group.replication[0].arn
    type             = "forward"
  }
}
