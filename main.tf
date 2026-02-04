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

module "aws_lb"{
  source = "./autoscale"
  aws_vpc = module.aws_vpc.vpc_id
  web_sg  = module.aws_security_group.ext_sg_id
  public_subnet1_id = module.aws_vpc.public_subnet_ids[0]
  public_subnet2_id = module.aws_vpc.public_subnet_ids[1]
  key_name = var.key_name
}

