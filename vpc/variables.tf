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
variable "azs" {
  default = ["us-east-1a", "us-east-1b"]
}