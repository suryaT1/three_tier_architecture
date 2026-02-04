data "aws_ami" "amazon_linux2" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_launch_template" "web_lt" {
  name_prefix   = "web-lt-"
  image_id      = data.aws_ami.amazon_linux2.id
  instance_type = "t2.micro"

  key_name = var.key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [var.web_sg]
  }

  user_data = base64encode(file("${path.module}/userdata.sh"))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "web-instance"
    }
  }
}


resource "aws_lb_target_group" "web_tg" {
  name     = "web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id  = var.aws_vpc
  health_check {
    path = "/"
  }
}

resource "aws_autoscaling_group" "web_asg" {

  desired_capacity = 2
  max_size         = 3
  min_size         = 1

    vpc_zone_identifier = [
    var.public_subnet1_id,
    var.public_subnet2_id
  ]

  launch_template {
    id      = aws_launch_template.web_lt.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.web_tg.arn]

  tag {
    key                 = "Name"
    value               = "web-asg"
    propagate_at_launch = true
  }
}

resource "aws_lb" "external_lb" {
  name               = "external-lb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [var.web_sg]

  subnets = [
    var.public_subnet1_id,
    var.public_subnet2_id
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
