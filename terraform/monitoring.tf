# SNS Topic for all alerts
resource "aws_sns_topic" "alerts" {
  name = "lab-alerts"
  tags = { Name = "lab-alerts" }
}

# Email subscription
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "lab-dashboard"
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "ASG CPU Utilization"
          region  = var.aws_region
          view    = "timeSeries"
          stacked = false
          period  = 300
          stat    = "Average"
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", aws_autoscaling_group.web.name, { label = "ASG Average CPU" }]
          ]
          annotations = {
            horizontal = [{
              value = 70
              label = "70% threshold"
              color = "#ff6961"
            }]
          }
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 42
        width  = 12
        height = 6
        properties = {
          title   = "RDS CPU Utilization"
          region  = var.aws_region
          view    = "timeSeries"
          stacked = false
          period  = 300
          stat    = "Average"
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", aws_db_instance.main.identifier, { label = "RDS CPU %" }]
          ]
          annotations = {
            horizontal = [{
              value = 80
              label = "80% threshold"
              color = "#ff6961"
            }]
          }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 42
        width  = 12
        height = 6
        properties = {
          title   = "RDS Database Connections"
          region  = var.aws_region
          view    = "timeSeries"
          stacked = false
          period  = 60
          stat    = "Average"
          metrics = [
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", aws_db_instance.main.identifier, { label = "Connections" }]
          ]
          annotations = { horizontal = [] }
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 48
        width  = 12
        height = 6
        properties = {
          title   = "RDS Free Storage Space"
          region  = var.aws_region
          view    = "timeSeries"
          stacked = false
          period  = 300
          stat    = "Average"
          metrics = [
            ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", aws_db_instance.main.identifier, { label = "Free Storage (bytes)" }]
          ]
          annotations = { horizontal = [] }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 48
        width  = 12
        height = 6
        properties = {
          title   = "RDS Read/Write Latency"
          region  = var.aws_region
          view    = "timeSeries"
          stacked = false
          period  = 60
          stat    = "Average"
          metrics = [
            ["AWS/RDS", "ReadLatency", "DBInstanceIdentifier", aws_db_instance.main.identifier, { label = "Read" }],
            ["AWS/RDS", "WriteLatency", "DBInstanceIdentifier", aws_db_instance.main.identifier, { label = "Write" }]
          ]
          annotations = { horizontal = [] }
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 36
        width  = 12
        height = 6
        properties = {
          title   = "EC2 Memory Usage"
          region  = var.aws_region
          view    = "timeSeries"
          stacked = false
          period  = 60
          stat    = "Average"
          metrics = [
            ["Lab/EC2", "mem_used_percent", "AutoScalingGroupName", aws_autoscaling_group.web.name, { label = "Memory %" }]
          ]
          annotations = {
            horizontal = [{
              value = 80
              label = "80% threshold"
              color = "#ff6961"
            }]
          }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 36
        width  = 12
        height = 6
        properties = {
          title   = "EC2 Disk Usage"
          region  = var.aws_region
          view    = "timeSeries"
          stacked = false
          period  = 60
          stat    = "Average"
          metrics = [
            ["Lab/EC2", "disk_used_percent", "AutoScalingGroupName", aws_autoscaling_group.web.name, { label = "Disk %" }]
          ]
          annotations = {
            horizontal = [{
              value = 80
              label = "80% threshold"
              color = "#ff6961"
            }]
          }
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 24
        width  = 24
        height = 6
        properties = {
          title   = "WAF Blocked Requests"
          region  = var.aws_region
          view    = "timeSeries"
          stacked = false
          period  = 60
          stat    = "Sum"
          metrics = [
            ["AWS/WAFV2", "BlockedRequests", "WebACL", "lab-waf", "Region", var.aws_region, "Rule", "AWSManagedRulesCommonRuleSet", { label = "Common Rules" }],
            ["AWS/WAFV2", "BlockedRequests", "WebACL", "lab-waf", "Region", var.aws_region, "Rule", "AWSManagedRulesSQLiRuleSet", { label = "SQLi" }],
            ["AWS/WAFV2", "BlockedRequests", "WebACL", "lab-waf", "Region", var.aws_region, "Rule", "RateLimitRule", { label = "Rate Limit" }],
            ["AWS/WAFV2", "BlockedRequests", "WebACL", "lab-waf", "Region", var.aws_region, "Rule", "AWSManagedRulesAmazonIpReputationList", { label = "IP Reputation" }]
          ]
          annotations = { horizontal = [] }
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 30
        width  = 24
        height = 6
        properties = {
          title   = "ALB HTTP vs HTTPS Request Count"
          region  = var.aws_region
          view    = "timeSeries"
          stacked = false
          period  = 300
          stat    = "Sum"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.main.arn_suffix, { label = "Total Requests" }],
            ["AWS/ApplicationELB", "HTTPCode_ELB_3XX_Count", "LoadBalancer", aws_lb.main.arn_suffix, { label = "HTTP→HTTPS Redirects" }]
          ]
          annotations = { horizontal = [] }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "ALB Request Count"
          region  = var.aws_region
          view    = "timeSeries"
          stacked = false
          period  = 300
          stat    = "Sum"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.main.arn_suffix]
          ]
          annotations = { horizontal = [] }
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "ALB HTTP 5xx Errors"
          region  = var.aws_region
          view    = "timeSeries"
          stacked = false
          period  = 60
          stat    = "Sum"
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", aws_lb.main.arn_suffix]
          ]
          annotations = { horizontal = [] }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "ALB Target Response Time"
          region  = var.aws_region
          view    = "timeSeries"
          stacked = false
          period  = 300
          stat    = "Average"
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.main.arn_suffix]
          ]
          annotations = {
            horizontal = [{
              value = 2
              label = "2s threshold"
              color = "#ff6961"
            }]
          }
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          title   = "EFS Throughput"
          region  = var.aws_region
          view    = "timeSeries"
          stacked = false
          period  = 300
          stat    = "Average"
          metrics = [
            ["AWS/EFS", "DataReadIOBytes", "FileSystemId", aws_efs_file_system.web_efs.id, { label = "Read" }],
            ["AWS/EFS", "DataWriteIOBytes", "FileSystemId", aws_efs_file_system.web_efs.id, { label = "Write" }]
          ]
          annotations = { horizontal = [] }
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 18
        width  = 12
        height = 6
        properties = {
          title   = "ASG Instance Count"
          region  = var.aws_region
          view    = "timeSeries"
          stacked = false
          period  = 60
          stat    = "Average"
          metrics = [
            ["AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", aws_autoscaling_group.web.name, { label = "In Service" }],
            ["AWS/AutoScaling", "GroupDesiredCapacity", "AutoScalingGroupName", aws_autoscaling_group.web.name, { label = "Desired" }]
          ]
          annotations = { horizontal = [] }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 18
        width  = 12
        height = 6
        properties = {
          title   = "ALB Requests Per Target"
          region  = var.aws_region
          view    = "timeSeries"
          stacked = false
          period  = 60
          stat    = "Sum"
          metrics = [
            ["AWS/ApplicationELB", "RequestCountPerTarget", "TargetGroup", aws_lb_target_group.web.arn_suffix, { label = "Requests/target" }]
          ]
          annotations = {
            horizontal = [{
              value = 1000
              label = "Scale out threshold"
              color = "#ff6961"
            }]
          }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6
        properties = {
          title   = "EFS Burst Credit Balance"
          region  = var.aws_region
          view    = "timeSeries"
          stacked = false
          period  = 300
          stat    = "Average"
          metrics = [
            ["AWS/EFS", "BurstCreditBalance", "FileSystemId", aws_efs_file_system.web_efs.id]
          ]
          annotations = {
            horizontal = [{
              value = 1000000000
              label = "1GB warning threshold"
              color = "#ff6961"
            }]
          }
        }
      }
    ]
  })
}

# --- CloudWatch Alarms ---
# Alert if WAF is blocking an unusual number of requests

resource "aws_cloudwatch_metric_alarm" "waf_blocked" {
  alarm_name          = "waf-high-blocked-requests"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "BlockedRequests"
  namespace           = "AWS/WAFV2"
  period              = 300
  statistic           = "Sum"
  threshold           = 100
  alarm_description   = "WAF is blocking an unusually high number of requests"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    WebACL = "lab-waf"
    Region = var.aws_region
    Rule   = "ALL"
  }
}

/*
# EC2-a CPU high
resource "aws_cloudwatch_metric_alarm" "cpu_high_a" {
  alarm_name          = "web-a-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "web-server-a CPU above 70%"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = aws_instance.web.id
  }
}

# EC2-b CPU high
resource "aws_cloudwatch_metric_alarm" "cpu_high_b" {
  alarm_name          = "web-b-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "web-server-b CPU above 70%"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = aws_instance.web_b.id
  }
}
*/

resource "aws_cloudwatch_metric_alarm" "asg_cpu_high" {
  alarm_name          = "asg-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "ASG average CPU above 70%"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }
}

# ALB 5xx errors
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "ALB returning too many 5xx errors"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }
}

# ALB high latency
resource "aws_cloudwatch_metric_alarm" "alb_latency" {
  alarm_name          = "alb-high-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Average"
  threshold           = 2
  alarm_description   = "ALB target response time above 2 seconds"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }
}

# EFS burst credit low
resource "aws_cloudwatch_metric_alarm" "efs_burst_low" {
  alarm_name          = "efs-burst-credit-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "BurstCreditBalance"
  namespace           = "AWS/EFS"
  period              = 300
  statistic           = "Average"
  threshold           = 1000000000
  alarm_description   = "EFS burst credit balance is low"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    FileSystemId = aws_efs_file_system.web_efs.id
  }
}

resource "aws_cloudwatch_log_group" "httpd_access" {
  name              = "/lab/httpd/access"
  retention_in_days = 7
  tags              = { Name = "lab-httpd-access-logs" }
}

resource "aws_cloudwatch_log_group" "httpd_error" {
  name              = "/lab/httpd/error"
  retention_in_days = 7
  tags              = { Name = "lab-httpd-error-logs" }
}

resource "aws_cloudwatch_log_group" "user_data" {
  name              = "/lab/ec2/user-data"
  retention_in_days = 7
  tags              = { Name = "lab-user-data-logs" }
}
