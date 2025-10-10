# output "api-gateway-url" {
#   value = "${aws_api_gateway_stage.example.invoke_url}${aws_api_gateway_resource.Resource.path}"
#   # value = aws_api_gateway_deployment.example.invoke_url
# }
output "api-gateway-url" {
  value = "${aws_api_gateway_stage.v1.invoke_url}${aws_api_gateway_resource.Resource.path}"
}
output "api-gateway-base-url" {
  value = aws_api_gateway_stage.v1.invoke_url
}

output "amplify_app_id" {
  value = aws_amplify_app.et_ai_poc_portal.id
}

output "amplify_default_domain" {
  value = aws_amplify_app.et_ai_poc_portal.default_domain
}

output "amplify_branch_url" {
  value = "https://${aws_amplify_branch.amplify_branch.branch_name}.${aws_amplify_app.et_ai_poc_portal.default_domain}"
}


# output "auth_secret_arn" {
#   value = aws_secretsmanager_secret.auth_secret.arn
# }

output "authorizer_function_name" {
  description = "Name of the API Gateway authorizer Lambda function."
  value       = aws_lambda_function.api_gateway_authorizer.function_name
}

output "authorizer_function_arn" {
  description = "ARN of the API Gateway authorizer Lambda function."
  value       = aws_lambda_function.api_gateway_authorizer.arn
}

output "authorizer_invoke_arn" {
  description = "Invoke ARN of the API Gateway authorizer Lambda function."
  value       = aws_lambda_function.api_gateway_authorizer.invoke_arn
}

output "authorizer_version" {
  description = "Published version of the authorizer Lambda (set because publish=true)."
  value       = aws_lambda_function.api_gateway_authorizer.version
}

# rag pipeline outputs
output "api_gw_base_url" {
  description = "Base invoke URL for the stage"
  value       = aws_api_gateway_stage.v1.invoke_url
}

output "api_gw_agent_url" {
  description = "POST /agent full URL"
  value       = "${aws_api_gateway_stage.v1.invoke_url}agent"
}

output "bucket_name" {
  value = aws_s3_bucket.data_source.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.data_source.arn
}
output "collection_enpdoint" {
  value = aws_opensearchserverless_collection.collection.collection_endpoint
}

output "dashboard_endpoint" {
  value = aws_opensearchserverless_collection.collection.dashboard_endpoint
}
# output "function_arn" {
#   value = module.lambda_function_container_image.lambda_function_arn
# }

# output "function_name" {
#   value = module.lambda_function_container_image.lambda_function_name
# }
# output "custom_domain_url" {
#   value = "https://${aws_amplify_branch.amplify_branch.branch_name}.${var.domain_name}"
# }