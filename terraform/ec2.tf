# ec2.tf

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

/*
resource "aws_instance" "web" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.private.id       # 👈 private subnet now
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  key_name                    = aws_key_pair.main.key_name
  associate_public_ip_address = false                       # 👈 no public IP


  depends_on = [
    aws_route_table_association.private_a,  # wait for private routes
    aws_route_table_association.private_b,
    aws_efs_mount_target.private_a,         # wait for EFS
    aws_efs_mount_target.private_b,
    aws_nat_gateway.nat,                    # wait for NAT
    aws_nat_gateway.natb
  ]
  user_data = <<-EOF
    #!/bin/bash
    set -e
    exec > /var/log/user-data.log 2>&1

    # Installation of Web Sevices
    sudo yum update -y
    sudo yum install -y httpd amazon-efs-utils
    
    # Mount EFS
    mkdir -p /var/www/html
    mount -t efs -o tls ${aws_efs_file_system.web_efs.id}:/ /var/www/html

    # Add EFS to FSTAB
    echo "${aws_efs_file_system.web_efs.id}:/ /var/www/html efs _netdev,tls 0 0" | sudo tee -a /etc/fstab


    # Permission(s) & File
    echo "<h1>Hello from $(hostname) — served from EFS</h1>" | sudo tee /var/www/html/index.html
    sudo chmod 755 /var/www/html
    sudo chmod 644 /var/www/html/index.html
    sudo chown apache:apache /var/www/html/index.html

    # Start Web Services
    sudo systemctl start httpd
    sudo systemctl enable httpd
  EOF

  tags = { Name = "web-server" }
}

resource "aws_instance" "web_b" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.private_b.id      # AZ-b
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  key_name                    = aws_key_pair.main.key_name
  associate_public_ip_address = false

  user_data = <<-EOF
    #!/bin/bash
    set -e
    exec > /var/log/user-data.log 2>&1

    echo "=== Starting user_data at $(date) ==="

    sleep 10

    echo "=== Installing httpd and NFS utils ==="
    sudo yum update -y
    sudo yum install -y httpd amazon-efs-utils

    echo "=== Mounting EFS ==="
    sudo mkdir -p /var/www/html
    sudo mount -t efs -o tls ${aws_efs_file_system.web_efs.id}:/ /var/www/html

    # Persist mount across reboots
    echo "${aws_efs_file_system.web_efs.id}:/ /var/www/html efs _netdev,tls 0 0" | sudo tee -a /etc/fstab

    echo "=== Setting permissions ==="
    sudo chmod 755 /var/www/html
    sudo chown apache:apache /var/www/html

    echo "=== Starting httpd ==="
    sudo systemctl start httpd
    sudo systemctl enable httpd

    echo "=== Done at $(date) ==="
  EOF

  depends_on = [
    aws_route_table_association.private_a,
    aws_route_table_association.private_b,
    aws_efs_mount_target.private_a,
    aws_efs_mount_target.private_b,
    aws_nat_gateway.nat,
    aws_nat_gateway.natb,
    aws_efs_file_system.web_efs
  ]

  tags = { Name = "web-server-b" }
}
*/

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_a.id # public subnet
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  key_name                    = aws_key_pair.main.key_name
  associate_public_ip_address = true # needs public IP

  tags = { Name = "bastion" }
}
