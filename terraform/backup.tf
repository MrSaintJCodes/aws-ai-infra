# IAM role for AWS Backup
resource "aws_iam_role" "backup" {
  name = "lab-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "backup.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

# Backup vault — where backups are stored
resource "aws_backup_vault" "main" {
  name = "lab-backup-vault"
  tags = { Name = "lab-backup-vault" }
}

# Backup plan — daily at 2am, keep for 7 days
resource "aws_backup_plan" "main" {
  name = "lab-backup-plan"

  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 2 * * ? *)" # 2am UTC daily

    lifecycle {
      delete_after = 7 # keep 7 days of backups
    }
  }

  tags = { Name = "lab-backup-plan" }
}

# Backup selection — backs up EFS and both EC2s
resource "aws_backup_selection" "main" {
  name         = "lab-backup-selection"
  plan_id      = aws_backup_plan.main.id
  iam_role_arn = aws_iam_role.backup.arn

  resources = [
    aws_efs_file_system.web_efs.arn
  ]
}
