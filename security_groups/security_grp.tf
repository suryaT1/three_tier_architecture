resource "aws_security_group" "ext_sg" {
  name   = "external-sg"
  vpc_id = var.vpc_id
}

resource "aws_security_group" "public_sg" {
  name   = "public-sg"
  vpc_id = var.vpc_id
}

resource "aws_security_group" "internal_sg" {
  name   = "internal-sg"
  vpc_id = var.vpc_id
}

resource "aws_security_group" "app_sg" {
  name   = "app-sg"
  vpc_id = var.vpc_id
}

resource "aws_security_group" "db_sg" {
  name   = "db-sg"
  vpc_id = var.vpc_id
}

# Security Group rules

resource "aws_security_group_rule" "internet_to_ext" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ext_sg.id
}

resource "aws_security_group_rule" "ext_to_public" {
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.public_sg.id
  security_group_id        = aws_security_group.ext_sg.id
}
resource "aws_security_group_rule" "ext_to_public2" {
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  cidr_blocks = [ "0.0.0.0/0" ]
  security_group_id        = aws_security_group.ext_sg.id
}


resource "aws_security_group_rule" "public_from_ext" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ext_sg.id
  security_group_id        = aws_security_group.public_sg.id
}

resource "aws_security_group_rule" "public_to_internal" {
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.internal_sg.id
  security_group_id        = aws_security_group.public_sg.id
}
resource "aws_security_group_rule" "internal_from_public" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.public_sg.id
  security_group_id        = aws_security_group.internal_sg.id
}

resource "aws_security_group_rule" "internal_to_app" {
  type                     = "egress"
  from_port                = 4000
  to_port                  = 4000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app_sg.id
  security_group_id        = aws_security_group.internal_sg.id
}

resource "aws_security_group_rule" "app_from_internal" {
  type                     = "ingress"
  from_port                = 4000
  to_port                  = 4000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.internal_sg.id
  security_group_id        = aws_security_group.app_sg.id
}


resource "aws_security_group_rule" "app_to_db" {
  type                     = "egress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.db_sg.id
  security_group_id        = aws_security_group.app_sg.id
}
resource "aws_security_group_rule" "db_from_app" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app_sg.id
  security_group_id        = aws_security_group.db_sg.id
}
