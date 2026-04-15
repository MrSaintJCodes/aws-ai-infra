# SSM Parameter — stores EFS ID for reference
resource "aws_ssm_parameter" "efs_id" {
  name  = "/lab/efs/filesystem-id"
  type  = "String"
  value = aws_efs_file_system.web_efs.id
  tags  = { Name = "lab-efs-id" }
}

# SSM Parameter — stores ALB DNS
resource "aws_ssm_parameter" "alb_dns" {
  name  = "/lab/alb/dns-name"
  type  = "String"
  value = aws_lb.main.dns_name
  tags  = { Name = "lab-alb-dns" }
}

# SSM Parameter — stores region
resource "aws_ssm_parameter" "region" {
  name  = "/lab/config/region"
  type  = "String"
  value = var.aws_region
  tags  = { Name = "lab-region" }
}