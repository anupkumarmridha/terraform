
provider "aws" {
  region = "us-east-1"
}


resource "aws_s3_bucket" "example" {
  bucket = "anup-tf-test-bucket"

  tags = {
    Name        = "Anup bucket"
    Environment = "Dev"
  }
}