########################################
# OpenSearch Serverless (AOSS) - Secure
########################################

# Encryption policy (AWS owned key)
resource "aws_opensearchserverless_security_policy" "encryption_policy" {
  name        = "example-encryption-policy"
  type        = "encryption"
  description = "encryption policy for ${var.collection_name}"

  policy = jsonencode({
    Rules = [
      {
        Resource     = ["collection/${var.collection_name}"]
        ResourceType = "collection"
      }
    ]
    AWSOwnedKey = true
  })
}

# Collection (Vector Search)
resource "aws_opensearchserverless_collection" "collection" {
  name       = var.collection_name
  type       = "VECTORSEARCH"
  depends_on = [aws_opensearchserverless_security_policy.encryption_policy]
}

# VPC endpoint for AOSS (ENIs in PRIVATE subnets; SG from network.tf)
resource "aws_opensearchserverless_vpc_endpoint" "vpc_endpoint" {
  name               = "${var.collection_name}-aoss-vpce"
  vpc_id             = aws_vpc.main.id
  subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_group_ids = [aws_security_group.endpoint_access.id]
}

# Network policy:
# - VPC-only access for the collection endpoint (via the above VPCE)
# - Public access for Dashboards
resource "aws_opensearchserverless_security_policy" "network_policy" {
  name        = "example-network-policy"
  type        = "network"
  description = "public access for dashboards, VPC access for collection endpoint"

  policy = jsonencode([
    {
      Description = "VPC access for collection endpoint"
      Rules = [
        {
          ResourceType = "collection"
          Resource     = ["collection/${var.collection_name}"]
        }
      ]
      AllowFromPublic = false
      SourceVPCEs     = [aws_opensearchserverless_vpc_endpoint.vpc_endpoint.id]
    },
    {
      Description = "Public access for dashboards"
      Rules = [
        {
          ResourceType = "dashboard"
          # Dashboards are tied to collections
          Resource = ["collection/${var.collection_name}"]
        }
      ]
      AllowFromPublic = true
    }
  ])
}
# locals {
#   cd_user_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/devops-app-cd-user"

#   aoss_data_principals = compact([
#     var.ec2_instance_role_name != "" ? "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.ec2_instance_role_name}" : "",
#     local.cd_user_arn,
#   ])
# }


resource "aws_opensearchserverless_access_policy" "data_access_policy" {
  name        = "example-data-access-policy"
  type        = "data"
  description = "allow index and collection access"

  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "index"
          Resource     = ["index/${var.collection_name}/*"]
          Permission   = ["aoss:*"]
        },
        {
          ResourceType = "collection"
          Resource     = ["collection/${var.collection_name}"]
          Permission   = ["aoss:*"]
        }
      ]
      Principal = [
        #"arn:aws:iam::061051228043:role/ssm-role", # EC2 instance IAM role
        data.aws_caller_identity.current.arn # Terraform runner identity
      ]
    }
  ])
}
