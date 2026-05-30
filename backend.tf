terraform {
  backend "s3" {
    bucket         = "shivani-capstone-terraform-state-341777288699"
    key            = "capstone/terraform.tfstate"
    region         = "eu-north-1"
    use_lockfile   = true
    encrypt        = true
  }
}
