output "api-gateway-url" {
  value = "${aws_api_gateway_stage.example.invoke_url}${aws_api_gateway_resource.Resource.path}"
  # value = aws_api_gateway_deployment.example.invoke_url
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
# output "custom_domain_url" {
#   value = "https://${aws_amplify_branch.amplify_branch.branch_name}.${var.domain_name}"
# }