terraform {
  backend "s3" {
    bucket = "seunghyeon-saving-remote-state"
    key = "eks/terraform.tfstate"
    region = "ap-northeast-2"
    encrypt = true
  }
}