data "aws_ami" "amazon_linux2" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_launch_configuration" "web_launch_config" {
  name_prefix   = "web-launch-config-"
  image_id      = data.aws_ami.amazon_linux2.id
  instance_type = "t3.micro"
  key_name      = "three-tier-architecture"

  security_groups = [aws_security_group.web_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "Hello from ASG" > /var/www/html/index.html
              EOF
}

resource "aws_lb_target_group" "web_tg" {
  name     = "web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id  = aws_vpc.three_tier_vpc.id

  health_check {
    path = "/"
  }
}
resource "aws_autoscaling_group" "web_asg" {
  launch_configuration = aws_launch_configuration.web_launch_config.name

  min_size         = 2
  max_size         = 5
  desired_capacity = 3

  vpc_zone_identifier = [
    aws_subnet.public1.id,
    aws_subnet.public2.id
  ]

  target_group_arns = [aws_lb_target_group.web_tg.arn]

  tag {
    key                 = "Name"
    value               = "web-server"
    propagate_at_launch = true
  }
}
resource "aws_lb" "external_lb" {
  name               = "external-lb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.lb_sg.id]

  subnets = [
    aws_subnet.public1.id,
    aws_subnet.public2.id
  ]
}

resource "aws_lb_listener" "public_listener" {
  load_balancer_arn = aws_lb.external_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}


resource "aws_lb_listener" "public_listener" {
  load_balancer_arn = aws_lb.external_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
  
}