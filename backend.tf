terraform {
  backend "s3" {
    bucket = "terraformstatefile0502"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}