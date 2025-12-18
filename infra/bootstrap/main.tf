terraform {
  required_version = ">= 1.5.0"
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
  state_bucket = "${var.name}-tfstate-${random_id.suffix.hex}-${var.aws_region}"
  lock_table   = "${var.name}-tflock-${random_id.suffix.hex}"
}

resource "aws_s3_bucket" "tf_state" {
  bucket = local.state_bucket
}

resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket                  = aws_s3_bucket.tf_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_dynamodb_table" "tf_lock" {
  name         = local.lock_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# --- GitHub OIDC role for Actions ---
data "aws_iam_policy_document" "github_oidc_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_owner}/${var.github_repo}:*"]
    }
  }
}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

resource "aws_iam_role" "github_actions" {
  name               = "${var.name}-github-actions"
  assume_role_policy = data.aws_iam_policy_document.github_oidc_assume.json
}

# Minimal permissions for this demo (Terraform-managed S3 + CloudFront + state access)
data "aws_iam_policy_document" "github_actions_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:CreateBucket",
      "s3:DeleteBucket",
      "s3:PutBucketPolicy",
      "s3:GetBucketPolicy",
      "s3:DeleteBucketPolicy",
      "s3:PutBucketVersioning",
      "s3:GetBucketVersioning",
      "s3:PutBucketEncryption",
      "s3:PutBucketPublicAccessBlock",
      "s3:GetBucketPublicAccessBlock",
      "s3:PutLifecycleConfiguration",
      "s3:GetLifecycleConfiguration",
      "s3:ListBucket",
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObjectAcl",
      "s3:AbortMultipartUpload",
      "s3:ListBucketMultipartUploads",
      "s3:ListMultipartUploadParts"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "cloudfront:CreateDistribution",
      "cloudfront:UpdateDistribution",
      "cloudfront:GetDistribution",
      "cloudfront:GetDistributionConfig",
      "cloudfront:DeleteDistribution",
      "cloudfront:CreateOriginAccessControl",
      "cloudfront:GetOriginAccessControl",
      "cloudfront:UpdateOriginAccessControl",
      "cloudfront:DeleteOriginAccessControl",
      "cloudfront:CreateInvalidation",
      "cloudfront:ListInvalidations"
    ]
    resources = ["*"]
  }

  # Required by Terraform
  statement {
    effect = "Allow"
    actions = [
      "iam:GetRole",
      "iam:PassRole"
    ]
    resources = ["*"]
  }

  # Remote state access
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.tf_state.arn,
      "${aws_s3_bucket.tf_state.arn}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:DescribeTable"
    ]
    resources = [aws_dynamodb_table.tf_lock.arn]
  }
}

resource "aws_iam_role_policy" "github_actions_inline" {
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.github_actions_policy.json
}

output "tf_state_bucket" {
  value = aws_s3_bucket.tf_state.bucket
}

output "tf_lock_table" {
  value = aws_dynamodb_table.tf_lock.name
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}
