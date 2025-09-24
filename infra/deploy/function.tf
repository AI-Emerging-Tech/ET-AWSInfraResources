
# resource "aws_secretsmanager_secret" "elastic_credentials" {
#   name = var.elasticsearch_connection_secret
# }

# resource "aws_secretsmanager_secret_version" "elastic_credentials" {
#   secret_id = data.aws_secretsmanager_secret.elastic_credentials.id
# }

# locals {
#   elastic_credentials = jsondecode(data.aws_secretsmanager_secret_version.elastic_credentials.secret_string)
# }

module "lambda_function_container_image" {
  source         = "terraform-aws-modules/lambda/aws"
  function_name  = "agent"
  create_package = false
  image_uri      = "703671915761.dkr.ecr.us-east-1.amazonaws.com/marketplace/lambda-agent:v1.0"
  package_type   = "Image"
  timeout        = 900

  environment_variables = {
    ELASTICSEARCH_ENDPOINT = var.elasticsearch_private_https_endpoint
    # ELASTICSEARCH_USER     = local.elastic_credentials.username
    ELASTICSEARCH_PASSWORD = var.elasticsearch_connection_secret
  }

  vpc_subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  vpc_security_group_ids = [
    aws_security_group.endpoint_access.id
  ]




  attach_network_policy = true

  memory_size = 1024

  policies           = ["arn:aws:iam::aws:policy/AmazonBedrockFullAccess"]
  attach_policies    = true
  number_of_policies = 1
}