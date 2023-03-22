
##################################################################################
# TERRAFORM CONFIG
##################################################################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "random" {
}
provider "aws" {
  region = "us-east-1"
}


#Random ID for unique naming
resource "random_integer" "rand" {
  min = 10000
  max = 99999
}
locals {
  common_tags = {
    project      = "s3-backend"
    billing_code = "0001-backend"
  }

  s3_bucket_name = lower("tf-backend-${random_integer.rand.result}")
  DdB_table_name = lower("tf-backend-locks-${random_integer.rand.result}")
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = local.s3_bucket_name

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_s3_bucket_versioning" "bucket_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_encryp" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = local.DdB_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

output "s3_bucket_name" {
  value = local.s3_bucket_name
}

output "Ddb_table_name" {
  value = local.DdB_table_name
}
