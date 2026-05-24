
resource "aws_launch_template" "lt" {
  name_prefix   = "lojaplus"
  image_id      = "ami-0c55b159cbfafe1f0" # exemplo Amazon Linux
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.app.id]
}

resource "aws_autoscaling_group" "asg" {
  desired_capacity = 2
  max_size         = 6
  min_size         = 2

  vpc_zone_identifier = aws_subnet.app[*].id
  target_group_arns   = [aws_lb_target_group.tg.arn]

  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }
}

resource "aws_autoscaling_policy" "cpu" {
  name                   = "cpu-policy"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.asg.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70
  }
}
