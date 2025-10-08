########################################
# OpenSearch Serverless (AOSS) - Secure
########################################

# # Name guardrails (3..40 chars, a-z0-9 only — enforced by locals in variables.tf)
# resource "null_resource" "validate_collection_name" {
#   triggers = { name = var.collection_name }
#   lifecycle {
#     precondition {
#       condition     = length(var.collection_name) >= 3 && length(var.collection_name) <= 40
#       error_message = "collection_name must be 3..40 chars, a-z0-9 only."
#     }
#   }
# }

############################
# AOSS Collection (vector) #
############################
resource "aws_opensearchserverless_collection" "collection" {
  name        = var.collection_name
  type        = "VECTORSEARCH"
  description = "Vector store collection ${var.collection_name}"
  tags = {
    Name = "${local.prefix}-collection"

  }
}

#########################################
# Encryption Policy (AWS-owned KMS key) #
#########################################
resource "aws_opensearchserverless_security_policy" "encryption" {
  name = "${var.collection_name}-encryption"
  type = "encryption"

  policy = jsonencode({
    Rules = [
      {
        ResourceType = "collection"
        Resource     = ["collection/${var.collection_name}"]
      }
    ]
    # Use AWS-owned key by default. If you migrate to a CMK, replace with KMS key configuration.
    AWSOwnedKey = true
  })
}

##########################################################
# Network Policy: restrict collection to our VPC endpoint
##########################################################
# VPC endpoint for AOSS (ENIs in PRIVATE subnets; SG from network.tf)
resource "aws_opensearchserverless_vpc_endpoint" "vpc_endpoint" {
  name               = "${var.collection_name}-aoss-vpce"
  vpc_id             = aws_vpc.main.id
  subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_group_ids = [aws_security_group.endpoint_access.id]
}

resource "aws_opensearchserverless_security_policy" "network" {
  name = "${var.collection_name}-network"
  type = "network"

  # Allow access only via our specific VPC endpoint (AOSS expects "vpc/<vpce-id>")
  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "vpc"
          Resource     = ["vpc/${aws_opensearchserverless_vpc_endpoint.vpc_endpoint.id}"]
        }
      ]
    }
  ])

  depends_on = [aws_opensearchserverless_vpc_endpoint.vpc_endpoint]
}

#####################################
# Data Access Policy (data plane)   #
# Hard-coded principals             #
#####################################

# Hard-coded principals (no workflow/env var needed)
locals {
  aoss_hardcoded_principals = [
    "arn:aws:iam::061051228043:user/devops-app-cd-user"
    # Add more ARNs as needed, e.g.:
    # "arn:aws:iam::<ACCOUNT_ID>:role/your-app-role",
  ]
}

# Full access (API + Dashboards) for principals
resource "aws_opensearchserverless_access_policy" "data_full" {
  name = "${var.collection_name}-data"
  type = "data"

  policy = jsonencode([
    {
      Description = "Full collection access for principals"
      Rules = [
        {
          ResourceType = "collection"
          Resource     = ["collection/${var.collection_name}"]
          Permission   = ["aoss:APIAccessAll", "aoss:DashboardsAccessAll"]
        }
      ]
      Principal = local.aoss_hardcoded_principals
    }
  ])

  depends_on = [
    aws_opensearchserverless_collection.collection,
    aws_opensearchserverless_security_policy.encryption,
    aws_opensearchserverless_security_policy.network
  ]
}

# If you prefer least-privilege for an app without dashboards, comment the block above
# and use this instead:
#
# resource "aws_opensearchserverless_access_policy" "data_minimal" {
#   name = "${var.collection_name}-data"
#   type = "data"
#   policy = jsonencode([
#     {
#       Description = "Minimal document & index privileges for app"
#       Rules = [
#         {
#           ResourceType = "collection"
#           Resource     = ["collection/${var.collection_name}"]
#           Permission   = ["aoss:CreateIndex", "aoss:ReadDocument", "aoss:WriteDocument"]
#         }
#       ]
#       Principal = local.aoss_hardcoded_principals
#     }
#   ])
#   depends_on = [
#     aws_opensearchserverless_collection.collection,
#     aws_opensearchserverless_security_policy.encryption,
#     aws_opensearchserverless_security_policy.network
#   ]
# }