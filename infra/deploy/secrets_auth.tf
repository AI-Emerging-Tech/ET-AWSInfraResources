# ########################################
# # Secrets Manager: Authorizer token
# ########################################

# # Secret container only (no value here -> avoids TF state holding plaintext)
# resource "aws_secretsmanager_secret" "auth_secret" {
#   name        = "${local.prefix}/auth/secret"
#   description = "Shared token for API Gateway Lambda authorizer"
#   tags = {
#     Name = "${local.prefix}-auth-secret"
#   }
#   # If you have your own KMS key, provide it via var.secrets_kms_key_arn
#   kms_key_id = var.secrets_kms_key_arn != "" ? var.secrets_kms_key_arn : null
# }


# # Allow the existing Lambda role to read the secret
# data "aws_iam_policy_document" "authorizer_secrets" {
#   statement {
#     effect = "Allow"
#     actions = [
#       "secretsmanager:GetSecretValue",
#       "secretsmanager:DescribeSecret"
#     ]
#     resources = [aws_secretsmanager_secret.auth_secret.arn]
#   }

#   # If using a customer-managed KMS key for the secret, allow decrypt
#   dynamic "statement" {
#     for_each = var.secrets_kms_key_arn != "" ? [1] : []
#     content {
#       effect    = "Allow"
#       actions   = ["kms:Decrypt"]
#       resources = [var.secrets_kms_key_arn]
#     }
#   }
# }

# resource "aws_iam_role_policy" "authorizer_secrets" {
#   name   = "authorizer-secrets-access"
#   role   = aws_iam_role.iam-role.id
#   policy = data.aws_iam_policy_document.authorizer_secrets.json
# }

# output "auth_secret_arn" {
#   value       = aws_secretsmanager_secret.auth_secret.arn
#   description = "ARN of the authorizer shared secret"
# }
