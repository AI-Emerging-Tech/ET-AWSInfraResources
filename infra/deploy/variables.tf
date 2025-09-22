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

variable "aws_dynamodb_table" {
  description = "lambda authorizer user table"
  default     = "users"
}

variable "az_client" {
  description = "azure clien id secret"
}

variable "az_tenant" {
  description = "azure tenant id secret"
}

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

