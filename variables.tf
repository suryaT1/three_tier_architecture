variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "vpc_ipadr" {
  default = "10.0.0.0/24"
  type    = string
}
variable "public_sb" {
  default = ["10.0.0.0/28", "10.0.0.16/28"]
  type    = list(string)
}
variable "private_sb" {
  default = ["10.0.0.32/28", "10.0.0.48/28"]
  type    = list(string)
}
variable "db_sb" {
  default = ["10.0.0.64/28", "10.0.0.80/28"]
  type    = list(string)
}
variable "aws_subnet_pub" {
  default = ""
}
variable "ec2_instance_profile_name" {
  default = ""
}
variable "key_name" {
  default = "three-tier-architecture"
}
variable "available_zone" {
  default = ["us-east-1a", "us-east-1b"]
  type    = list(string)
}
variable "bucket_name" {
  default = "sudhe-tf-state-bucket"
}