# Find amis for the Prometheus and Grafana instances.
data "aws_ami" "default" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-arm64-gp2"]
  }
}

# Place an SSH key.
resource "aws_key_pair" "default" {
  key_name   = "prometheus"
  public_key = file("id_rsa.pub")
}

# Create a security group for Prometheus.
resource "aws_security_group" "prometheus" {
  description = "Prometheus"
  name_prefix = "Prometheus"
  vpc_id      = module.vault.vpc_id
}

# Allow ssh access to Prometheus.
resource "aws_security_group_rule" "prometheus-ssh" {
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "SSH"
  from_port         = 22
  protocol          = "TCP"
  security_group_id = aws_security_group.prometheus.id
  to_port           = 22
  type              = "ingress"
}

# Allow access to Prometheus.
resource "aws_security_group_rule" "prometheus" {
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Prometheus"
  from_port         = 9090
  protocol          = "TCP"
  security_group_id = aws_security_group.prometheus.id
  to_port           = 9090
  type              = "ingress"
}

# Allow internet from the instances. Required for package installations.
resource "aws_security_group_rule" "prometheus-internet" {
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "internet"
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.prometheus.id
  to_port           = 0
  type              = "egress"
}

# Create the Prometheus host.
resource "aws_instance" "prometheus" {
  ami                         = data.aws_ami.default.id
  associate_public_ip_address = true
  instance_type               = "t4g.small"
  key_name                    = aws_key_pair.default.key_name
  monitoring                  = true
  subnet_id                   = module.vault.bastion_subnet_id
  user_data = base64encode(templatefile("${path.module}/user_data_prometheus.sh.tpl",
    {
      credenial = "hvs.OBFUSCATEDOBFUSCATEDOBFU"
      target    = aws_route53_record.default.fqdn
    }))
  user_data_replace_on_change = true
  vpc_security_group_ids      = [aws_security_group.prometheus.id]
  root_block_device {
    volume_size           = "32"
    volume_type           = "gp2"
    encrypted             = true
    delete_on_termination = true
  }
  tags = {
    Name = "prometheus"
  }
}
