/*
output "web_public_ip" {
  value       = aws_instance.web.public_ip
  description = "Public IP of the web server"
}

output "web_url" {
  value       = "http://${aws_instance.web.public_ip}"
  description = "URL to access Apache"
}
*/

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "efs_dns_name" {
  value = aws_efs_file_system.web_efs.dns_name
}

output "acm_certificate_arn" {
  value = aws_acm_certificate.lab.arn
}

output "flow_logs_bucket" {
  value = aws_s3_bucket.flow_logs.bucket
}

output "ssm_connect_web_a" {
  description = "Command to connect to an ASG instance via SSM"
  value       = "aws ssm start-session --target <instance-id> --region ${var.aws_region}"
}

output "cloudwatch_dashboard_url" {
  value = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=lab-dashboard"
}

output "sns_topic_arn" {
  value = aws_sns_topic.alerts.arn
}

output "rds_endpoint" {
  value = aws_db_instance.main.address
}

