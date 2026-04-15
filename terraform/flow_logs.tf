# S3 bucket for VPC flow logs
resource "aws_s3_bucket" "flow_logs" {
  bucket        = "lab-vpc-flow-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
  tags          = { Name = "lab-flow-logs" }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "flow_logs" {
  bucket                  = aws_s3_bucket.flow_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle rule — expire logs after 30 days to save cost
resource "aws_s3_bucket_lifecycle_configuration" "flow_logs" {
  bucket = aws_s3_bucket.flow_logs.id

  rule {
    id     = "expire-flow-logs"
    status = "Enabled"

    filter {}

    expiration {
      days = 30
    }
  }
}

# Enable VPC flow logs → S3
resource "aws_flow_log" "main" {
  vpc_id       = aws_vpc.main.id
  traffic_type = "ALL" # captures ACCEPT, REJECT, and ALL traffic

  log_destination      = aws_s3_bucket.flow_logs.arn
  log_destination_type = "s3"

  tags = { Name = "lab-flow-logs" }
}

resource "aws_s3_bucket_policy" "flow_logs" {
  bucket = aws_s3_bucket.flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AWSLogDeliveryWrite"
      Effect = "Allow"
      Principal = {
        Service = "delivery.logs.amazonaws.com"
      }
      Action   = "s3:PutObject"
      Resource = "${aws_s3_bucket.flow_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      Condition = {
        StringEquals = {
          "s3:x-amz-acl" = "bucket-owner-full-control"
        }
      }
      },
      {
        Sid    = "AWSLogDeliveryAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.flow_logs.arn
    }]
  })
}

# IAM role for flow logs
resource "aws_iam_role" "flow_logs" {
  name = "lab-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "flow_logs" {
  name = "lab-flow-logs-policy"
  role = aws_iam_role.flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:PutObject",
        "s3:GetBucketAcl"
      ]
      Resource = [
        aws_s3_bucket.flow_logs.arn,
        "${aws_s3_bucket.flow_logs.arn}/*"
      ]
    }]
  })
}

# Get current account ID for unique bucket name
data "aws_caller_identity" "current" {}
