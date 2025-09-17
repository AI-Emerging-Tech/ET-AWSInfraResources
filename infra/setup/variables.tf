variable "tf_state_bucket" {
  description = "Name of s3 bucket in AWS for storing TF State"
  default     = "devops-et-ai-tf-state"
}

variable "et_ai_lambda_function" {
  description = "Name of s3 bucket in AWS for storing lambda functions"
  default     = "et-ai-lambda-function"
}

variable "tf_state_lock_table" {
  description = "Name of the Dynamo DB table for TF state locking"
  default     = "devops-et-ai-tf-lock"
}

variable "project" {
  description = "Project name for tagging resources"
  default     = "devops-iac"
}

variable "contact" {
  description = "Contact information for tagging resources"
  default     = "dheerajvarma.bhupathiraju@valuemomentum.com"

}