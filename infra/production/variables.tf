variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "eu-central-1"
}

variable "name" {
  type        = string
  description = "Name prefix for resources"
  default     = "adel-cicd"
}

variable "cloudfront_price_class" {
  type        = string
  description = "CloudFront price class (keep low for cost control)"
  default     = "PriceClass_100"
}
