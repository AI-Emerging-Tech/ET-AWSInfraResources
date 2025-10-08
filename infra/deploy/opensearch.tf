########################################
# OpenSearch Serverless (AOSS) - Secure
########################################

# Name guardrails (3..40 chars, a-z0-9 only — enforced by locals in variables.tf)
resource "null_resource" "validate_collection_name" {
  triggers = { name = local.collection_name_sanitized }
  lifecycle {
    precondition {
      condition     = length(local.collection_name_sanitized) >= 3 && length(local.collection_name_sanitized) <= 40
      error_message = "collection_name must be 3..40 chars, a-z0-9 only."
    }
  }
}

############################
# AOSS Collection (vector) #
############################
resource "aws_opensearchserverless_collection" "collection" {
  name        = local.collection_name_sanitized
  type        = "VECTORSEARCH"
  description = "Vector store collection ${local.collection_name_sanitized}"
  tags = {
    Name        = local.collection_name_sanitized
    Environment = terraform.workspace
  }
}

#########################################
# Encryption Policy (AWS-owned KMS key) #
#########################################
resource "aws_opensearchserverless_security_policy" "encryption" {
  name = "${local.collection_name_sanitized}-encryption"
  type = "encryption"

  policy = jsonencode({
    Rules = [
      {
        ResourceType = "collection"
        Resource     = ["collection/${local.collection_name_sanitized}"]
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
  name               = "${local.collection_name_sanitized}-aoss-vpce"
  vpc_id             = aws_vpc.main.id
  subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_group_ids = [aws_security_group.endpoint_access.id]
}


resource "aws_opensearchserverless_security_policy" "network" {
  name = "${local.collection_name_sanitized}-network"
  type = "network"

  # Allow access only via our VPC endpoint
  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "collection"
          Resource     = ["collection/${local.collection_name_sanitized}"]
        },
        {
          ResourceType = "dashboard"
          Resource     = ["collection/${local.collection_name_sanitized}"]
        },
        {
          ResourceType = "vpc"
          Resource     = [aws_opensearchserverless_vpc_endpoint.vpc_endpoint.id]
        }
      ]
    }
  ])

  depends_on = [aws_opensearchserverless_vpc_endpoint.vpc_endpoint]
}

#####################################
# Data Access Policy (data plane)   #
# Choose one of the two blocks:     #
#  - FULL access (API + Dashboards) #
#  - LEAST privilege (API only)     #
#####################################

# (A) Full access (API + Dashboards) for principals
resource "aws_opensearchserverless_access_policy" "data_full" {
  name = "${local.collection_name_sanitized}-data"
  type = "data"

  policy = jsonencode([
    {
      Description = "Full collection access for principals"
      Rules = [
        {
          ResourceType = "collection"
          Resource     = ["collection/${local.collection_name_sanitized}"]
          Permission   = ["aoss:APIAccessAll", "aoss:DashboardsAccessAll"]
        }
      ]
      Principal = local.aoss_principals
    }
  ])

  depends_on = [
    aws_opensearchserverless_collection.collection,
    aws_opensearchserverless_security_policy.encryption,
    aws_opensearchserverless_security_policy.network
  ]
}

# (B) If you prefer least-privilege for an app without dashboards, comment (A) and use:
# resource "aws_opensearchserverless_access_policy" "data_minimal" {
#   name = "${local.collection_name_sanitized}-data"
#   type = "data"
#   policy = jsonencode([
#     {
#       Description = "Minimal document & index privileges for app"
#       Rules = [
#         {
#           ResourceType = "collection"
#           Resource     = ["collection/${local.collection_name_sanitized}"]
#           Permission   = ["aoss:CreateIndex", "aoss:ReadDocument", "aoss:WriteDocument"]
#         }
#       ]
#       Principal = local.aoss_principals
#     }
#   ])
#   depends_on = [
#     aws_opensearchserverless_collection.collection,
#     aws_opensearchserverless_security_policy.encryption,
#     aws_opensearchserverless_security_policy.network
#   ]
# }

