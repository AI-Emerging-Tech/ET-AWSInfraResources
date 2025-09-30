

# Creates an encryption security policy
resource "aws_opensearchserverless_security_policy" "encryption_policy" {
  name        = "${local.prefix}-aoss-encryption"
  type        = "encryption"
  description = "encryption policy for ${var.collection_name}"
  policy = jsonencode({
    Rules = [
      {
        Resource = [
          "collection/${var.collection_name}"
        ],
        ResourceType = "collection"
      }
    ],
    AWSOwnedKey = true
  })
}

# # Creates a collection
  resource "aws_opensearchserverless_collection" "collection" {
    name = var.collection_name
    type = "VECTORSEARCH"
    depends_on = [aws_opensearchserverless_security_policy.encryption_policy]
}

# Creates a network security policy
resource "aws_opensearchserverless_security_policy" "network_policy" {
  name        = "${local.prefix}-aoss-network"
  type        = "network"
  description = "public access for dashboard, VPC access for collection endpoint"
  policy = jsonencode([
    {
      Description = "VPC access for collection endpoint",
      Rules = [
        {
          ResourceType = "collection",
          Resource = [
            #"collection/${var.collection_name}"
            "collection/${aws_opensearchserverless_collection.collection.name}"
          ]
        }
      ],
      AllowFromPublic = false,
      SourceVPCEs = [
        aws_opensearchserverless_vpc_endpoint.aoss.id
      ]
    }
    # {
    #   Description = "Public access for dashboards",
    #   Rules = [
    #     {
    #       ResourceType = "dashboard"
    #       Resource = [
    #         "collection/${var.collection_name}"
    #       ]
    #     }
    #   ],
    #   AllowFromPublic = true
    # }
  ])
}



# Creates a data access policy
resource "aws_opensearchserverless_access_policy" "data_access_policy" {
  name        = "${local.prefix}-aoss-access"
  type        = "data"
  description = "allow index and collection access"
  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "index",
          Resource = [
            #"index/${var.collection_name}/*"
            "index/${aws_opensearchserverless_collection.collection.name}/*"
          ],
          Permission = [
            "aoss:*"
          ]
        },
        {
          ResourceType = "collection",
          Resource = [
            #"collection/${var.collection_name}"
            "collection/${aws_opensearchserverless_collection.collection.name}"
          ],
          Permission = [
            "aoss:*"
          ]
        }
      ],
      Principal = [
        data.aws_caller_identity.current.arn
        #local.aoss_principals
      ]
    }
  ])
}