########################################
# OpenSearch Serverless (AOSS) - Secure
########################################


# --- Name guardrails (keep your variable contract; enforce constraints) ---
resource "null_resource" "validate_collection_name" {
  triggers = { name = local.collection_name_sanitized }
  lifecycle {
    precondition {
      condition     = length(local.collection_name_sanitized) >= 3 && length(local.collection_name_sanitized) <= 40
      error_message = "collection_name must be 3..40 chars, a-z0-9 only."
    }
  }
}

# Encryption policy (AWS owned key)
resource "aws_opensearchserverless_security_policy" "encryption_policy" {
  name        = "example-encryption-policy"
  type        = "encryption"
  description = "encryption policy for ${local.collection_name_sanitized}"

  policy = jsonencode({
    Rules = [
      {
        Resource     = ["collection/${local.collection_name_sanitized}"]
        ResourceType = "collection"
      }
    ]
    AWSOwnedKey = true
  })
}

# VPC endpoint for AOSS (ENIs in PRIVATE subnets; SG from network.tf)
resource "aws_opensearchserverless_vpc_endpoint" "vpc_endpoint" {
  name               = "${local.collection_name_sanitized}-aoss-vpce"
  vpc_id             = aws_vpc.main.id
  subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_group_ids = [aws_security_group.endpoint_access.id]
}

# Network policy:
# - VPC-only access for the collection endpoint (via the above VPCE)
# - Public access for Dashboards tied to the collection
resource "aws_opensearchserverless_security_policy" "network_policy" {
  name        = "example-network-policy"
  type        = "network"
  description = "public access for dashboards, VPC access for collection endpoint"

  policy = jsonencode([
    {
      Description = "VPC access for collection endpoint"
      Rules = [
        { ResourceType = "collection", Resource = ["collection/${local.collection_name_sanitized}"] }
      ]
      AllowFromPublic = false
      SourceVPCEs     = [aws_opensearchserverless_vpc_endpoint.vpc_endpoint.id]
    },
    {
      Description = "Public access for dashboards"
      Rules = [
        # 'dashboard' Rules are associated with collections
        { ResourceType = "dashboard", Resource = ["collection/${local.collection_name_sanitized}"] }
      ]
      AllowFromPublic = true
    }
  ])

  depends_on = [aws_opensearchserverless_vpc_endpoint.vpc_endpoint]
}

# Collection (VECTORSEARCH) — create only after both policies exist
resource "aws_opensearchserverless_collection" "collection" {
  name = local.collection_name_sanitized
  type = "VECTORSEARCH"
  depends_on = [
    aws_opensearchserverless_security_policy.encryption_policy,
    aws_opensearchserverless_security_policy.network_policy
  ]
}

# Data Access Policy — use created collection name, keep your principal pattern
resource "aws_opensearchserverless_access_policy" "data_access_policy" {
  name        = "example-data-access-policy"
  type        = "data"
  description = "allow index and collection access"

  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "index"
          Resource     = ["index/${aws_opensearchserverless_collection.collection.name}/*"]
          Permission   = ["aoss:*"]
        },
        {
          ResourceType = "collection"
          Resource     = ["collection/${aws_opensearchserverless_collection.collection.name}"]
          Permission   = ["aoss:*"]
        }
      ]
      Principal = [
        # Keep your CD runner identity; add more ARNs (roles/users) if needed
        data.aws_caller_identity.current.arn
      ]
    }
  ])

  depends_on = [aws_opensearchserverless_collection.collection]
}
