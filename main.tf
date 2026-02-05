provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "three-tier-demo" {
  cidr_block           = var.vpc_ipadr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "three-tier-demo-vpc"
  }
}

resource "aws_subnet" "public-subnet" {
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.three-tier-demo.id
  cidr_block              = var.public_sb[count.index]
  availability_zone       = element(var.available_zone, count.index)
  count                   = length(var.public_sb)
  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "private_sb" {
  vpc_id            = aws_vpc.three-tier-demo.id
  cidr_block        = var.private_sb[count.index]
  availability_zone = element(var.available_zone, count.index)
  count             = length(var.private_sb)
  tags = {
    Name = "private-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "db-sg" {
  vpc_id            = aws_vpc.three-tier-demo.id
  cidr_block        = var.db_sb[count.index]
  availability_zone = element(var.available_zone, count.index)
  count             = length(var.db_sb)
  tags = {
    Name = "db-subnet-${count.index + 1}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.three-tier-demo.id
  tags = {
    Name = "three-tier-demo-igw"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.three-tier-demo.id
  tags = {
    Name = "public-rt"
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public-rt-ass" {
  route_table_id = aws_route_table.public_rt.id
  subnet_id      = aws_subnet.public-subnet[count.index].id
  count          = length(var.public_sb)
}

resource "aws_eip" "nat_eip" {
  tags = {
    "name" : "nat-eip"
  }
}
resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public-subnet[0].id
  tags = {
    Name = "three-tier-demo-nat-gw"
  }
}
resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.three-tier-demo.id
  tags = {
    Name = "private-rt"
  }
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gw.id
  }
}
resource "aws_route_table_association" "private-rt-ass" {
  route_table_id = aws_route_table.private-rt.id
  subnet_id      = aws_subnet.private_sb[count.index].id
  count          = length(var.private_sb)
}

resource "aws_security_group" "public-sg" {
  name        = "public-sg"
  description = "Allow HTTP and SSH traffic"
  vpc_id      = aws_vpc.three-tier-demo.id
  tags = {
    Name = "public-sg"
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "private-sg" {
  name        = "private-sg"
  description = "Allow traffic from public subnet"
  vpc_id      = aws_vpc.three-tier-demo.id

  ingress {
    from_port       = 4000
    to_port         = 4000
    protocol        = "tcp"
    security_groups = [aws_security_group.public-sg.id]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "private-sg"
  }
}

resource "aws_security_group" "db-sg" {
  name        = "db-sg"
  description = "Allow traffic from private subnet"
  vpc_id      = aws_vpc.three-tier-demo.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.private-sg.id]
  }
  tags = {
    Name = "db-sg"
  }

}
resource "aws_iam_role" "role_for_ec2" {
  name = "ec2-s3-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.role_for_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_role_policy_attachment" "s3_attach" {
  role       = aws_iam_role.role_for_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.role_for_ec2.name
}

resource "aws_instance" "test" {
  ami                    = "ami-0532be01f26a3de55"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public-subnet[0].id
  vpc_security_group_ids = [aws_security_group.public-sg.id]
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "public-ec2-instance"
  }
}

# external load balancer

resource "aws_security_group" "external_sg" {
  name        = "external-sg"
  description = "Allow external access"
  vpc_id      = aws_vpc.three-tier-demo.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.public-sg.id]
  }
}

resource "aws_lb_target_group" "external-tg" {
  name     = "external-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.three-tier-demo.id
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}
resource "aws_lb" "external-lb" {
  name               = "external-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.external_sg.id]
  subnets            = aws_subnet.public-subnet[*].id
  tags = {
    "name" : "external-lb"
  }
}

resource "aws_lb_listener" "external-lb-listener" {
  load_balancer_arn = aws_lb.external-lb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.external-tg.arn
  }
}

resource "aws_launch_template" "web-servers" {

  name_prefix   = "web-server-"
  image_id      = "ami-0532be01f26a3de55"
  instance_type = "t2.micro"

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  network_interfaces {
    security_groups             = [aws_security_group.public-sg.id]
    associate_public_ip_address = true
  }
  tags = {
    Name = "web"
  } 

  key_name = var.key_name

  user_data = base64encode(<<-EOF
                #!/bin/bash
                yum update -y
                yum install -y nginx
                systemctl start nginx
                systemctl enable nginx
                echo "Hello from Web Server" > /var/www/html/index.html
                EOF
  )
    tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "web"
    }
  }


}

resource "aws_autoscaling_group" "web_asg" {
  name             = "web-asg"
  min_size         = 1
  max_size         = 3
  desired_capacity = 2

  vpc_zone_identifier = aws_subnet.public-subnet[*].id

  launch_template {
    id      = aws_launch_template.web-servers.id
    version = "$Latest"
  }
  tag {
  key                 = "Name"
  value               = "web"
  propagate_at_launch = true
}


  target_group_arns = [
    aws_lb_target_group.external-tg.arn
  ]
}

# internal load balancer

resource "aws_security_group" "internal_sg" {
  name        = "internal-sg"
  description = "Allow internal access"
  vpc_id      = aws_vpc.three-tier-demo.id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.public-sg.id]
  }
    tags = {
        Name = "internal-sg"
    }

  egress {
    from_port       = 4000
    to_port         = 4000
    protocol        = "tcp"
    security_groups = [aws_security_group.private-sg.id]
  }
}

resource "aws_lb_target_group" "internal-tg" {
  name     = "internal-tg"
  port     = 4000
  protocol = "HTTP"
  vpc_id   = aws_vpc.three-tier-demo.id
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}
resource "aws_lb" "internal-lb" {
  name               = "internallb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.internal_sg.id]
  subnets            = aws_subnet.private_sb[*].id
  tags = {
    "name" : "internal-lb"
  }
}
resource "aws_lb_listener" "internal-lb-listener" {
  load_balancer_arn = aws_lb.internal-lb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.internal-tg.arn
  }
}

resource "aws_launch_template" "app-servers" {

  name_prefix   = "app-server-"
  image_id      = "ami-0532be01f26a3de55"
  instance_type = "t2.micro"

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  network_interfaces {
    security_groups             = [aws_security_group.private-sg.id]
  }
    tags = {
    Name = "app"
  } 
  key_name = var.key_name

    user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y python3
    sudo dnf install -y python3-pip
    
    # sudo dnf install -y mariadb105-server

    # Install Flask
    pip3 install flask

    # Create app directory
    mkdir -p /opt/app
    cd /opt/app

    # Create Flask app
    cat <<EOT > app.py
    from flask import Flask
    app = Flask(__name__)

    @app.route("/")
    def home():
        return "Hello from App Server"

    app.run(host="0.0.0.0", port=4000)
    EOT

    # Run app in background
    nohup python3 /opt/app/app.py > /opt/app/app.log 2>&1 &
    EOF
    )
      tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "app"
    }
  }


}

resource "aws_autoscaling_group" "app_asg" {
  name             = "app-asg"
  min_size         = 1
  max_size         = 3
  desired_capacity = 2

  vpc_zone_identifier = aws_subnet.private_sb[*].id

  launch_template {
    id      = aws_launch_template.app-servers.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "app"
    propagate_at_launch = true
  }


  target_group_arns = [
    aws_lb_target_group.internal-tg.arn
  ]
}

resource "aws_security_group_rule" "allow_internal_alb_to_app" {
  type                     = "ingress"
  from_port                = 4000
  to_port                  = 4000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.private-sg.id
  source_security_group_id = aws_security_group.internal_sg.id
}

resource "aws_security_group_rule" "allow_internal_app_to_db" {
  type                     = "egress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.private-sg.id
  source_security_group_id = aws_security_group.db-sg.id
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name        = "db-subnet-group"
  description = "Subnet group for RDS database"

  subnet_ids = aws_subnet.db-sg[*].id

  tags = {
    Name = "db-subnet-group"
  }
}

resource "aws_db_instance" "database" {
  identifier              = "three-tier-db"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"

  allocated_storage       = 20
  storage_type            = "gp2"

  db_name                 = "appdb"
  username                = "admin"
  password                = "Admin12345!"

  publicly_accessible     = false
  skip_final_snapshot     = true
  deletion_protection     = false

  db_subnet_group_name    = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db-sg.id]

  tags = {
    Name = "three-tier-rds"
  }
}
