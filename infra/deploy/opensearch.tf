############################
# OpenSearch Serverless
############################

# Workspace-aware toggles (same pattern you use elsewhere)
locals {
  is_prod = terraform.workspace == "prod"

  # AOSS collection name must be [a-z0-9]{3,40}
  collection_name_lower = lower(var.collection_name)

  # Instead of regexreplace(), use regexall()+join() to keep only allowed chars.
  # This avoids the "unknown function regexreplace" parser error you've seen.
  collection_name_chars     = regexall("[a-z0-9]", local.collection_name_lower)
  collection_name_sanitized = join("", local.collection_name_chars)
}

# Validate final name (prevents "" or illegal lengths)
resource "null_resource" "validate_collection_name" {
  triggers = { name = local.collection_name_sanitized }

  lifecycle {
    precondition {
      condition     = length(local.collection_name_sanitized) >= 3 && length(local.collection_name_sanitized) <= 40
      error_message = "collection_name must be 3..40 chars after sanitization (a-z0-9 only)."
    }
    precondition {
      condition     = can(regex("^[a-z0-9]+$", local.collection_name_sanitized))
      error_message = "collection_name must match ^[a-z0-9]+$ after sanitization."
    }
  }
}



locals {
  aoss_admin_principals = compact([
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
    try(aws_iam_role.task_execution_role.arn, null), # ecs.tf
    try(aws_iam_role.app_task.arn, null),            # ecs.tf
    try(aws_iam_role.iam-role.arn, null),            # iam-role.tf  (note: resource name has a dash)
  ])
}

# --- Security Policies ---

# 1) ENCRYPTION policy (AWS managed KMS key; create FIRST)
resource "aws_opensearchserverless_security_policy" "encryption" {
  name = "${local.collection_name_sanitized}-encryption"
  type = "encryption"

  policy = jsonencode({
    AWSOwnedKey = true
    Rules = [{
      ResourceType = "collection"
      Resource     = ["collection/${local.collection_name_sanitized}"]
    }]
  })

  depends_on = [null_resource.validate_collection_name]
}

# 2a) DEV/DEMO: Public network (no Route53)
resource "aws_opensearchserverless_security_policy" "network_public" {
  count = local.is_prod ? 0 : 1
  name  = "${local.collection_name_sanitized}-network"
  type  = "network"

  policy = jsonencode([{
    Description     = "Public network policy for demo/dev (IAM auth still required)"
    AllowFromPublic = true
    Rules = [
      { ResourceType = "collection", Resource = ["collection/${local.collection_name_sanitized}"] },
      { ResourceType = "dashboard", Resource = ["collection/${local.collection_name_sanitized}"] }
    ]
  }])

  depends_on = [null_resource.validate_collection_name]
}

# 2b) PROD: Private via VPCE (AWS creates private hosted zones internally)
resource "aws_opensearchserverless_vpc_endpoint" "this" {
  count              = local.is_prod ? 1 : 0
  name               = "${local.collection_name_sanitized}-aoss-vpce"
  vpc_id             = aws_vpc.main.id
  subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_group_ids = [aws_security_group.endpoint_access.id]
}

resource "aws_opensearchserverless_security_policy" "network_private" {
  count = local.is_prod ? 1 : 0
  name  = "${local.collection_name_sanitized}-network"
  type  = "network"

  policy = jsonencode([{
    Description     = "Private network policy via AOSS VPCE (prod)"
    AllowFromPublic = false
    SourceVPCEs     = [aws_opensearchserverless_vpc_endpoint.this[0].id]
    Rules = [
      { ResourceType = "collection", Resource = ["collection/${local.collection_name_sanitized}"] },
      { ResourceType = "dashboard", Resource = ["collection/${local.collection_name_sanitized}"] }
    ]
  }])

  depends_on = [aws_opensearchserverless_vpc_endpoint.this]
}

# 3) DATA/DASHBOARD access policy — principals built locally (no GA inputs)
resource "aws_opensearchserverless_access_policy" "data_access" {
  name        = "${local.collection_name_sanitized}-data-access"
  type        = "data"
  description = "Allow index and dashboard access for the collection"

  policy = jsonencode([{
    Rules = [
      { ResourceType = "index", Resource = ["index/${local.collection_name_sanitized}/*"], Permission = ["aoss:*"] },
      { ResourceType = "collection", Resource = ["collection/${local.collection_name_sanitized}"], Permission = ["aoss:*"] }
    ],
    Principal = local.aoss_admin_principals
  }])

  # Static list (Terraform requires static depends_on)
  depends_on = [
    aws_opensearchserverless_security_policy.encryption,
    aws_opensearchserverless_security_policy.network_public,
    aws_opensearchserverless_security_policy.network_private,
  ]
}

# 4) The collection itself
resource "aws_opensearchserverless_collection" "collection" {
  name = local.collection_name_sanitized
  type = "VECTORSEARCH"

  # Ensure the policies exist before creating the collection
  depends_on = [
    aws_opensearchserverless_security_policy.encryption,
    aws_opensearchserverless_access_policy.data_access,
    aws_opensearchserverless_security_policy.network_public,
    aws_opensearchserverless_security_policy.network_private,
  ]
}
