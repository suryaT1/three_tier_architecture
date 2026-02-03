variable "vpc_id" {
  default = ""
}
variable "db_sg_id" {
  default = ""
}
variable "db_subnet_ids" {
  type = list(string)
}
