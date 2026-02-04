variable "aws_vpc" {
  description = "The AWS VPC ID"
  type        = string
}
variable "web_sg" {
  type = string
}
variable "public_subnet1_id" {
  type = string
}
variable "public_subnet2_id" {
  type = string
}
variable "key_name" {
  description = "The name of the EC2 key pair"
  type        = string
}