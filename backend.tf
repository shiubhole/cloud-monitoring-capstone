terraform {
  backend "s3" {
    bucket         = "capstone-terraform-state"
    key            = "capstone/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}