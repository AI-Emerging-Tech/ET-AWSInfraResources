############################
# Lambda: API Gateway Authorizer (TOKEN)
############################

resource "aws_lambda_function" "api_gateway_authorizer" {
  function_name    = "${local.prefix}-api-gateway-authorizer"
  filename         = "${path.module}/authorizer.zip"
  source_code_hash = filebase64sha256("${path.module}/authorizer.zip")
  role             = aws_iam_role.iam-role.arn

  handler     = "lambda_function.lambda_handler"
  runtime     = "python3.11"
  timeout     = 10
  memory_size = 256

  # NOTE: provide real values or leave "" if unused in your code
  environment {
    variables = {
      AUTH_SECRET  = var.auth_secret
      USERS_TABLE  = var.aws_dynamodb_table
      AZ_CLIENT_ID = var.az_client_id
      AZ_TENANT    = var.az_tenant_id
    }
  }
}

# Allow API Gateway to invoke the authorizer Lambda
resource "aws_lambda_permission" "allow_apigw_invoke_authorizer" {
  statement_id  = "AllowExecutionFromAPIGatewayAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_gateway_authorizer.function_name
  principal     = "apigateway.amazonaws.com"
  # allow from this API (any stage)
  source_arn = aws_api_gateway_rest_api.API.execution_arn
}
