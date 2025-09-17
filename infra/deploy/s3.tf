# ################
# # React on S3  #
# ################

# # Optional: discover current region/account (handy for policies/outputs)
# data "aws_region" "current" {}
# data "aws_caller_identity" "current" {}

# # ---- Bucket ----
# # Name: <prefix>-web (e.g., vamet-demo-web)
# resource "aws_s3_bucket" "Web" {
#   bucket = "${local.prefix}-web"

#   tags = {
#     Name    = "${local.prefix}-web"
#     Project = local.prefix
#   }
# }

# # Versioning is optional but useful for rollbacks
# resource "aws_s3_bucket_versioning" "WebVersioning" {
#   bucket = aws_s3_bucket.Web.id
#   versioning_configuration {
#     status = "Enabled"
#   }
# }

# # Default encryption (SSE-S3). Website endpoint still works fine.
# resource "aws_s3_bucket_server_side_encryption_configuration" "WebEnc" {
#   bucket = aws_s3_bucket.Web.id
#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm = "AES256"
#     }
#   }
# }

# # ---- Static Website Hosting ----
# # Use index.html for both index and error (SPA route fallback).
# resource "aws_s3_bucket_website_configuration" "WebSite" {
#   bucket = aws_s3_bucket.Web.id

#   index_document {
#     suffix = "index.html"
#   }

#   error_document {
#     key = "index.html"
#   }
# }

# # ---- Public Access (required for S3 website hosting) ----
# # To use the *website endpoint*, the bucket must be publicly readable.
# # We explicitly disable the “Block Public Access” guards on this bucket.
# resource "aws_s3_bucket_public_access_block" "WebPublic" {
#   bucket                  = aws_s3_bucket.Web.id
#   block_public_acls       = false
#   block_public_policy     = false
#   ignore_public_acls      = false
#   restrict_public_buckets = false
# }

# # Public-read policy for website objects (scoped to objects only, not the bucket itself)
# data "aws_iam_policy_document" "WebPublicReadDoc" {
#   statement {
#     sid    = "AllowPublicReadForWebsite"
#     effect = "Allow"
#     principals {
#       type        = "AWS"
#       identifiers = ["*"]
#     }
#     actions = ["s3:GetObject"]
#     resources = [
#       "${aws_s3_bucket.Web.arn}/*"
#     ]
#   }
# }

# resource "aws_s3_bucket_policy" "WebPolicy" {
#   bucket = aws_s3_bucket.Web.id
#   policy = data.aws_iam_policy_document.WebPublicReadDoc.json

#   depends_on = [aws_s3_bucket_public_access_block.WebPublic]
# }

# # ---- CORS (optional; useful if your app fetches APIs/assets from elsewhere) ----
# resource "aws_s3_bucket_cors_configuration" "WebCORS" {
#   bucket = aws_s3_bucket.Web.id

#   cors_rule {
#     allowed_methods = ["GET", "HEAD"]
#     allowed_origins = ["*"]
#     allowed_headers = ["*"]
#     max_age_seconds = 3600
#   }
# }

# # ---- Helpful Outputs ----
# output "s3_website_endpoint" {
#   description = "Public website endpoint (http) — paste into browser"
#   value       = aws_s3_bucket_website_configuration.WebSite.website_endpoint
# }

# output "s3_website_url" {
#   description = "Public website URL (http) — same as endpoint but as URL"
#   value       = aws_s3_bucket_website_configuration.WebSite.website_endpoint
# }

# output "s3_bucket_name" {
#   value = aws_s3_bucket.Web.bucket
# }
