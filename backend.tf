terraform {
  backend "s3" {
    bucket         = "aws_s3_bucket.mys3_bucket.name"
    key            = "terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "dynamodb-locking-table"
  }
}

