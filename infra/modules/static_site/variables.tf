variable "name" {
  type        = string
  description = "Logical name prefix for resources"
}

variable "bucket_name" {
  type        = string
  description = "S3 bucket name for the site assets"
}

variable "price_class" {
  type        = string
  description = "CloudFront price class"
  default     = "PriceClass_100"
}
