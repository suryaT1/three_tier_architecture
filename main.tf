provider "aws" {
  region = var.aws_region
}

module "aws_vpc" {
  source = "./vpc"
}
module "aws_security_group" {
  source = "./security_groups"
  vpc_id = module.aws_vpc.vpc_id
}
module "aws_iam_role" {
  source = "./iam"
}
module "aws_s3_bucket" {
  source = "./s3"
}
module "aws_db_instance" {
  source = "./rds"
  db_subnet_ids = module.aws_vpc.aws_subnet_db
}

data "aws_ami" "amazon_linux2" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
