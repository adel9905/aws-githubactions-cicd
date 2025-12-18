terraform {
  required_version = ">= 1.5.0"

  # Remote state is configured during terraform init using backend-config
  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "random_id" "suffix" {
  byte_length = 3
}

locals {
  bucket_name = "${var.name}-${random_id.suffix.hex}-${var.aws_region}"
}

module "site" {
  source      = "../modules/static_site"
  name        = var.name
  bucket_name = local.bucket_name
  price_class = var.cloudfront_price_class
}

output "bucket_name" {
  value = module.site.bucket_name
}

output "cloudfront_distribution_id" {
  value = module.site.cloudfront_distribution_id
}

output "site_url" {
  value = module.site.site_url
}
