terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "s3_basic" {
  source = "../.."

  name   = "example-basic-bucket-terraform"
  tags = {
    Environment = "dev"
    Project     = "example"
  }
}

output "bucket_name" {
  value = module.s3_basic.bucket_id
}
