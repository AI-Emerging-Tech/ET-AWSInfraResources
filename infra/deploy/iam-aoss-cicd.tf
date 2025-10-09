# Look up the existing GitHub CD IAM user
data "aws_iam_user" "devops_cd_user" {
  user_name = "devops-app-cd-user"
}

# Minimal permissions so Terraform can create/read/tag AOSS resources
resource "aws_iam_policy" "aoss_tf_permissions" {
  name        = "vamet-${terraform.workspace}-aoss-terraform-permissions"
  description = "Permissions required by Terraform to manage OpenSearch Serverless (AOSS) resources"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Tagging is required because the provider reads tags_all and you have default_tags enabled
      {
        Sid    = "AossTagging"
        Effect = "Allow"
        Action = [
          "aoss:ListTagsForResource",
          "aoss:TagResource",
          "aoss:UntagResource"
        ]
        Resource = "*"
      },
      # Collections CRUD/read
      {
        Sid    = "AossCollections"
        Effect = "Allow"
        Action = [
          "aoss:CreateCollection",
          "aoss:DeleteCollection",
          "aoss:GetCollection",
          "aoss:BatchGetCollection",
          "aoss:ListCollections"
        ]
        Resource = "*"
      },
      # Security & access policies (what your opensearch.tf creates first)
      {
        Sid    = "AossPolicies"
        Effect = "Allow"
        Action = [
          "aoss:CreateSecurityPolicy",
          "aoss:UpdateSecurityPolicy",
          "aoss:DeleteSecurityPolicy",
          "aoss:GetSecurityPolicy",
          "aoss:CreateAccessPolicy",
          "aoss:UpdateAccessPolicy",
          "aoss:DeleteAccessPolicy",
          "aoss:GetAccessPolicy"
        ]
        Resource = "*"
      },
      # VPCE (only needed if/when you run prod with private access)
      {
        Sid    = "AossVpcEndpoint"
        Effect = "Allow"
        Action = [
          "aoss:CreateVpcEndpoint",
          "aoss:DeleteVpcEndpoint",
          "aoss:BatchGetVpcEndpoint",
          "aoss:ListVpcEndpoints"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "attach_aoss_tf_permissions" {
  user       = data.aws_iam_user.devops_cd_user.user_name
  policy_arn = aws_iam_policy.aoss_tf_permissions.arn
}
