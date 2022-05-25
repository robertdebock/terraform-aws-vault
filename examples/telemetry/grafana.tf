# Create a security group for Grafan.
resource "aws_security_group" "grafana" {
  description = "Grafana"
  name_prefix = "Grafana"
  vpc_id      = module.vault.vpc_id
}

# Allow ssh access to Grafana.
resource "aws_security_group_rule" "grafana-ssh" {
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "SSH"
  from_port         = 22
  protocol          = "TCP"
  security_group_id = aws_security_group.grafana.id
  to_port           = 22
  type              = "ingress"
}

# Allow access to Grafana.
resource "aws_security_group_rule" "grafana" {
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Grafana"
  from_port         = 3000
  protocol          = "TCP"
  security_group_id = aws_security_group.grafana.id
  to_port           = 3000
  type              = "ingress"
}

# Allow internet from the instances. Required for package installations.
resource "aws_security_group_rule" "grafana-internet" {
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "internet"
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.grafana.id
  to_port           = 0
  type              = "egress"
}

# Create the Grafana host.
resource "aws_instance" "grafana" {
  ami                         = data.aws_ami.default.id
  associate_public_ip_address = true
  instance_type               = "t4g.small"
  key_name                    = aws_key_pair.default.key_name
  monitoring                  = true
  subnet_id                   = module.vault.bastion_subnet_id
  user_data                   = file("user_data_grafana.sh")
  user_data_replace_on_change = true
  vpc_security_group_ids      = [aws_security_group.grafana.id]
  root_block_device {
    volume_size           = "32"
    volume_type           = "gp2"
    encrypted             = true
    delete_on_termination = true
  }
  tags = {
    Name = "grafana"
  }
}

# Show the Grafana public IP.
output "grafana_public_ip" {
  description = "The Grafana public IP address."
  value       = aws_instance.grafana.public_ip
}

output "grafana_private_ip" {
  description = "The Grafana private IP address."
  value       = aws_instance.grafana.private_ip
}

# Configure Grafana to use Prometheus.
resource "grafana_data_source" "prometheus" {
  type = "prometheus"
  name = "prometheus"
  url  = "http://${aws_instance.prometheus.private_ip}:9090"
}

# Configure Grafana with a Vault dashboard.
resource "grafana_dashboard" "one" {
  config_json = file("grafana-vault-one.json")
}

resource "grafana_dashboard" "two" {
  config_json = file("grafana-vault-two.json")
}
