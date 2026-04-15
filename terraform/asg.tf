# Launch Template — defines what each new EC2 looks like when it scales out
resource "aws_launch_template" "web" {
  name_prefix   = "web-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.main.key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.ec2_sg.id]
  }

  user_data = base64encode(templatefile("${path.root}/data/scripts/user_data_web.sh", {
    efs_dns = aws_efs_file_system.web_efs.dns_name
    asg_name = "web-asg"
    db_host  = aws_db_instance.main.address
    db_name  = aws_db_instance.main.db_name
    db_user  = aws_db_instance.main.username
    db_pass  = var.db_password
    web_git_repo = var.web_git_repo
    ollama_host = aws_lb.ollama.dns_name
    ollama_model = var.ollama_model
    django_secret_key = var.web_django_secret_key
    alb_dns = aws_lb.main.dns_name
  }))

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "web-asg-instance" }
  }

  depends_on = [
    aws_efs_mount_target.private_a,
    aws_efs_mount_target.private_b
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "web" {
  name             = "web-asg"
  min_size         = 2
  max_size         = 4
  desired_capacity = 2
  vpc_zone_identifier = [
    aws_subnet.private.id,
    aws_subnet.private_b.id
  ]

  # Attach to the existing target group so ALB routes to ASG instances
  target_group_arns = [aws_lb_target_group.web.arn]

  # Use the launch template
  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  # Health check via ALB — more accurate than EC2 status checks
  health_check_type         = "ELB"
  health_check_grace_period = 120 # give instances 2 min to boot before checking

  # Replace instances automatically if they fail health checks
  #instance_refresh {
  #  strategy = "Rolling"
  #  preferences {
  #    min_healthy_percentage = 50  # keep at least 1 instance up during refresh
  #  }
  #}

  tag {
    key                 = "Name"
    value               = "web-asg-instance"
    propagate_at_launch = true
  }

  depends_on = [
    aws_route_table_association.private_a,
    aws_route_table_association.private_b,
    aws_nat_gateway.nat,
    aws_nat_gateway.natb
  ]
}

# Scaling Policy — target tracking based on ALB request count per instance
resource "aws_autoscaling_policy" "web_scale" {
  name                   = "web-request-scaling"
  autoscaling_group_name = aws_autoscaling_group.web.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${aws_lb.main.arn_suffix}/${aws_lb_target_group.web.arn_suffix}"
    }

    target_value     = 1000  # scale out when avg requests per instance exceeds 1000/min
    disable_scale_in = false # allow scale in when traffic drops
  }
}
