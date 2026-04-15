# Security group for Ansible control node
resource "aws_security_group" "ansible_sg" {
  vpc_id      = aws_vpc.main.id
  description = "Ansible control node"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "ansible-sg" }
}

# Allow Ansible control node to SSH into EC2s
resource "aws_security_group_rule" "ansible_to_ec2" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ansible_sg.id
  security_group_id        = aws_security_group.ec2_sg.id
}

# IAM role for Ansible control node
resource "aws_iam_role" "ansible" {
  name = "lab-ansible-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# Allow Ansible to describe EC2 instances for dynamic inventory
resource "aws_iam_role_policy" "ansible_ec2_read" {
  name = "ansible-ec2-read"
  role = aws_iam_role.ansible.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ec2:DescribeInstances",
        "ec2:DescribeTags"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_instance_profile" "ansible" {
  name = "lab-ansible-profile"
  role = aws_iam_role.ansible.name
}

# Ansible control node EC2
resource "aws_instance" "ansible" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_a.id
  vpc_security_group_ids      = [aws_security_group.ansible_sg.id]
  key_name                    = aws_key_pair.main.key_name
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ansible.name

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e
    exec > /var/log/ansible-setup.log 2>&1

    echo "=== Installing Ansible ==="
    sudo yum update -y
    sudo yum install -y python3 python3-pip git
    sudo pip3 install ansible boto3 botocore

    # Install AWS EC2 dynamic inventory plugin
    ansible-galaxy collection install amazon.aws

    echo "=== Ansible ready ==="
  EOF
  )

  tags = { Name = "ansible-control" }
}

output "ansible_control_ip" {
  value = aws_instance.ansible.public_ip
}
