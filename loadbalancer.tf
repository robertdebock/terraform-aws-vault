# Create a placement group that spreads.
resource "aws_placement_group" "default" {
  name         = var.vault_name
  spread_level = "rack"
  strategy     = "spread"
  tags         = local.tags
}

# Add a load balancer for the API/UI.
resource "aws_lb" "api" {
  internal        = var.vault_aws_lb_availability == "internal" ? true : false
  name            = "${var.vault_name}-api-${random_string.default.result}"
  security_groups = concat([aws_security_group.public.id, aws_security_group.private.id], var.vault_extra_security_group_ids)
  subnets         = local.public_subnet_ids
  tags            = local.api_tags
}

# Add a load balancer for replication.
resource "aws_lb" "replication" {
  count              = var.vault_allow_replication ? 1 : 0
  internal           = var.vault_aws_lb_availability == "internal" ? true : false
  load_balancer_type = "network"
  name               = "${var.vault_name}-replication-${random_string.default.result}"
  subnets            = local.public_subnet_ids
  tags               = local.replication_tags
}

# Create a load balancer target group for the API/UI.
resource "aws_lb_target_group" "api" {
  deregistration_delay = 10
  name_prefix          = "${var.vault_name}-"
  port                 = 8200
  protocol             = "HTTPS"
  stickiness {
    enabled = true
    type    = "lb_cookie"
  }
  tags   = local.api_tags
  vpc_id = local.vpc_id
  health_check {
    interval = 5
    # If vault_allow_replication is on: Only healthy nodes must receive traffic. (Otherwise the health_check on the route53 record will return non-healthy nodes.)
    # If telemetry is on: See TELEMETRY.md for an explanation
    matcher  = var.vault_allow_replication ? "200" : var.vault_enable_telemetry && !var.vault_enable_telemetry ? "200,472,473" : "200,429,472,473"
    path     = "/v1/sys/health"
    protocol = "HTTPS"
    timeout  = 2
  }
}

# Create a load balancer target group.
resource "aws_lb_target_group" "replication" {
  count       = var.vault_allow_replication ? 1 : 0
  name_prefix = "${var.vault_name}-"
  port        = 8201
  protocol    = "TCP"
  tags        = local.replication_tags
  vpc_id      = local.vpc_id
  # Traffic for 8201 should only go to the active Vault node.
  # https://support.hashicorp.com/hc/en-us/articles/4408887865363-Troubleshooting-Replication-Problems-During-Initial-Bootstrap
  health_check {
    interval = 10
    path     = "/v1/sys/health"
    port     = 8200
    protocol = "HTTPS"
  }
}

# Add a API listener to the loadbalancer.
resource "aws_lb_listener" "api" {
  certificate_arn   = var.vault_aws_certificate_arn
  load_balancer_arn = aws_lb.api.arn
  port              = var.vault_api_port
  protocol          = "HTTPS"
  tags              = local.api_tags
  default_action {
    target_group_arn = aws_lb_target_group.api.arn
    type             = "forward"
  }
}

resource "aws_lb_listener" "api_redirect" {
  load_balancer_arn = aws_lb.api.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = var.vault_api_port
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Add a replication listener to the loadbalancer.
resource "aws_lb_listener" "replication" {
  count             = var.vault_allow_replication ? 1 : 0
  load_balancer_arn = aws_lb.replication[0].arn
  port              = var.vault_replication_port
  protocol          = "TCP"
  tags              = local.replication_tags
  default_action {
    target_group_arn = aws_lb_target_group.replication[0].arn
    type             = "forward"
  }
}
