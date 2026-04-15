# EFS File System
resource "aws_efs_file_system" "web_efs" {
  creation_token = "web-efs"
  encrypted      = true

  tags = { Name = "web-efs" }
}

# Mount target in private subnet AZ-a
resource "aws_efs_mount_target" "private_a" {
  file_system_id  = aws_efs_file_system.web_efs.id
  subnet_id       = aws_subnet.private.id
  security_groups = [aws_security_group.efs_sg.id]
}

# Mount target in private subnet AZ-b
resource "aws_efs_mount_target" "private_b" {
  file_system_id  = aws_efs_file_system.web_efs.id
  subnet_id       = aws_subnet.private_b.id
  security_groups = [aws_security_group.efs_sg.id]
}
