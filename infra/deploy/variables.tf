# //////////////////////////////
# VARIABLES
# //////////////////////////////

variable "prefix" {
  description = "Prefix for resources in AWS"
  default     = "vamet"
}
variable "project" {
  description = "Project name for taggigng resources"
  default     = "devops-iac"
}
variable "contact" {
  description = "contact email for tagging resources"
  default     = "dheerajvarma.bhupathiraju@valuemomentum.com"
}

variable "db_username" {
  description = "Username for the recipe app api database"
  default     = "idpdbuser"
}

variable "db_password" {
  description = "Password for the Terraform database"
}

variable "ecr_proxy_image" {
  description = "Path to the ECR repo with the proxy image"
}

variable "ecr_app_image" {
  description = "Path to the ECR repo with the API image"
}

variable "ecr_tools_image" {
  description = "Path to the ECR repo with the tools image"
}

variable "django_secret_key" {
  description = "Secret key for Django"
}

# variable "AWS_REGION" {
#   default   = "us-east-1"
#   type      = string
#   sensitive = true
# }

# variable "AWS_ACCOUNT_ID" {
#   default   = "Your aws account number"
#   type      = string
#   sensitive = true
# }

variable "cd_github_access_token" {
  description = "The details of the github token"
}

variable "cd_github_repository" {
  type        = string
  description = "github repo url"
  default     = "https://github.com/AI-Emerging-Tech/ET-AI-Poc-Portal-s3"
}

variable "ui_app_name" {
  type        = string
  description = "AWS Amplify App Name"
  default     = "et-ai-poc-portal"
}

variable "ui_branch_name" {
  type        = string
  description = "AWS Amplify App Repo Branch Name"
  default     = "main"
}


variable "auth_secret" {
  description = "Auth secret for JWT decprition"
}

variable "users_table" {
  description = "lambda authorizer user table"
  default     = "user-details"
}

variable "az_client_id" {
  description = "azure clien id secret"
}

variable "az_tenant_id" {
  description = "azure tenant id secret"
}

# # rag pipleline variables setup
# variable "lambda_agent_function_name" {
#   type = string
# }

# variable "lambda_agent_function_arn" {
#   type = string
# }

variable "datasource_bucket_name" {
  description = "Optional explicit S3 bucket name. Leave blank to auto-generate."
  type        = string
  default     = "kb-storage"
}

variable "aws_region" {
  description = "The AWS region to create things in."
  default     = "us-east-1"
}

variable "collection_name" {
  description = "Name of the OpenSearch Serverless collection."
  default     = "etaivectorcollection"
}
# EC2 instance role that your app runs under; leave empty if you only call from the CD user
# variable "ec2_instance_role_name" {
#   description = "Name of the EC2 instance IAM role that runs the app (used in AOSS data policy)"
#   type        = string
#   default     = ""
# }

# locals {
#   aoss_principals = (length(var.aoss_allowed_principals) > 0)
#     ? var.aoss_allowed_principals
#     : [data.aws_caller_identity.current.arn]
# }

# variable "domain_name" {
#   type        = string
#   default     = "amplifyapp.com" #change this to your custom domain
#   description = "AWS Amplify Domain Name"
# }

# variable "dns_zone_name" {
#   description = "Domain name"
#   default     = "shribhavanifarm.com"
# }

# variable "subdomain" {
#   description = "Subdomain for each environment"
#   type        = map(string)

#   default = {
#     prod    = "api"
#     staging = "api.staging"
#     dev     = "api.dev"
#   }
# }

