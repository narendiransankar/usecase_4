terraform {
  required_version = ">= 1.0.0"

  backend "s3" {
    bucket = "hcl-test-backend-state"
    key    = "usecase4/terraform.tfstate"
    region = "us-east-1"
  }
}
