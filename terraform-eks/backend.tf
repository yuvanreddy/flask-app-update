terraform {
  backend "s3" {
    bucket         = "flask-terraform-state-638950891807943903"
    key            = "eks/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}