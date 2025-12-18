variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "eu-central-1"
}

variable "name" {
  type        = string
  description = "Name prefix for bootstrap resources"
  default     = "adel-cicd"
}

variable "github_owner" {
  type        = string
  description = "GitHub org/user that owns the repo"
  default     = "CHANGE_ME"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository name"
  default     = "CHANGE_ME"
}
