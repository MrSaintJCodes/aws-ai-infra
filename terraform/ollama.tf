# Security group for Ollama
resource "aws_security_group" "ollama_sg" {
  vpc_id      = aws_vpc.main.id
  description = "Ollama AI server"

  ingress {
    from_port       = 11434
    to_port         = 11434
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  ingress {
    from_port       = 11434
    to_port         = 11434
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.ansible_sg.id]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "ollama-sg" }
}

# Dedicated EFS for Ollama model storage
resource "aws_efs_file_system" "ollama_efs" {
  creation_token = "ollama-efs"
  encrypted      = true
  tags           = { Name = "ollama-efs" }
}

# EFS security group — allow Ollama instances to mount
resource "aws_security_group" "ollama_efs_sg" {
  vpc_id      = aws_vpc.main.id
  description = "Allow NFS from Ollama instances"

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ollama_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "ollama-efs-sg" }
}

# EFS mount targets — one per AZ
resource "aws_efs_mount_target" "ollama_a" {
  file_system_id  = aws_efs_file_system.ollama_efs.id
  subnet_id       = aws_subnet.private.id
  security_groups = [aws_security_group.ollama_efs_sg.id]
}

resource "aws_efs_mount_target" "ollama_b" {
  file_system_id  = aws_efs_file_system.ollama_efs.id
  subnet_id       = aws_subnet.private_b.id
  security_groups = [aws_security_group.ollama_efs_sg.id]
}

# Shared user_data for both Ollama instances
locals {
  ollama_user_data = base64encode(templatefile("${path.root}/data/scripts/ollama_instance.sh", {
    efs_dns      = aws_efs_file_system.ollama_efs.dns_name
    ollama_host  = var.ollama_host
    ollama_port  = var.ollama_port
    ollama_model = var.ollama_model
  }))
}

# Ollama instance A — AZ-a
resource "aws_instance" "ollama_a" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.medium"
  subnet_id                   = aws_subnet.private.id
  vpc_security_group_ids      = [aws_security_group.ollama_sg.id]
  key_name                    = aws_key_pair.main.key_name
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ec2.name

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = local.ollama_user_data

  depends_on = [
    aws_efs_mount_target.ollama_a,
    aws_efs_mount_target.ollama_b,
    aws_route_table_association.private_a,
    aws_nat_gateway.nat,
    aws_efs_file_system.ollama_efs
  ]

  tags = { Name = "ollama-server-a" }
}

# Ollama instance B — AZ-b
resource "aws_instance" "ollama_b" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.medium"
  subnet_id                   = aws_subnet.private_b.id
  vpc_security_group_ids      = [aws_security_group.ollama_sg.id]
  key_name                    = aws_key_pair.main.key_name
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ec2.name

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = base64encode(local.ollama_user_data)

  depends_on = [
    aws_efs_mount_target.ollama_a,
    aws_efs_mount_target.ollama_b,
    aws_route_table_association.private_b,
    aws_nat_gateway.natb,
    aws_efs_file_system.ollama_efs
  ]

  tags = { Name = "ollama-server-b" }
}

# Internal ALB for Ollama — load balances between both instances
resource "aws_lb" "ollama" {
  name               = "ollama-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ollama_sg.id]
  subnets            = [
    aws_subnet.private.id,
    aws_subnet.private_b.id
  ]
  tags = { Name = "ollama-alb" }
}

# Target group for Ollama instances
resource "aws_lb_target_group" "ollama" {
  name     = "ollama-tg"
  port     = 11434
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/api/tags"
    protocol            = "HTTP"
    matcher             = "200"
    port                = "11434"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = { Name = "ollama-tg" }
}

# Register both instances
resource "aws_lb_target_group_attachment" "ollama_a" {
  target_group_arn = aws_lb_target_group.ollama.arn
  target_id        = aws_instance.ollama_a.id
  port             = 11434
}

resource "aws_lb_target_group_attachment" "ollama_b" {
  target_group_arn = aws_lb_target_group.ollama.arn
  target_id        = aws_instance.ollama_b.id
  port             = 11434
}

# Listener
resource "aws_lb_listener" "ollama" {
  load_balancer_arn = aws_lb.ollama.arn
  port              = 11434
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ollama.arn
  }
}

# Store Ollama ALB endpoint in SSM
resource "aws_ssm_parameter" "ollama_host" {
  name  = "/lab/ollama/host"
  type  = "String"
  value = "http://${aws_lb.ollama.dns_name}:11434"
  tags  = { Name = "lab-ollama-host" }
}

output "ollama_alb_dns" {
  value = aws_lb.ollama.dns_name
}

output "ollama_host" {
  value = "http://${aws_lb.ollama.dns_name}:11434"
}

output "ollama_efs_id" {
  value = aws_efs_file_system.ollama_efs.id
}

output "ollama_efs_dns_name" {
  value = aws_efs_file_system.ollama_efs.dns_name
}
