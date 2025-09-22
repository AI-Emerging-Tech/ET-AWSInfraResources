############
# API Gateway #
############

resource "aws_api_gateway_rest_api" "API" {
  name        = "${local.prefix}-lambda-api"
  description = "lambda-api"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

############################
# Resource tree
# /
#   /api
#     /v1
#       /admin
#         /users
#       /{proxy+}     (protected by authorizer)
#   /auth             (public POST)
############################


resource "aws_api_gateway_resource" "Resource" {
  rest_api_id = aws_api_gateway_rest_api.API.id
  parent_id   = aws_api_gateway_rest_api.API.root_resource_id
  path_part   = "verify-json"
}

resource "aws_api_gateway_resource" "api" {
  rest_api_id = aws_api_gateway_rest_api.API.id
  parent_id   = aws_api_gateway_rest_api.API.root_resource_id
  path_part   = "api"
}

resource "aws_api_gateway_resource" "v1" {
  rest_api_id = aws_api_gateway_rest_api.API.id
  parent_id   = aws_api_gateway_resource.api.id
  path_part   = "v1"
}

resource "aws_api_gateway_resource" "admin" {
  rest_api_id = aws_api_gateway_rest_api.API.id
  parent_id   = aws_api_gateway_resource.v1.id
  path_part   = "admin"
}

resource "aws_api_gateway_resource" "users" {
  rest_api_id = aws_api_gateway_rest_api.API.id
  parent_id   = aws_api_gateway_resource.admin.id
  path_part   = "users"
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.API.id
  parent_id   = aws_api_gateway_resource.v1.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_resource" "auth" {
  rest_api_id = aws_api_gateway_rest_api.API.id
  parent_id   = aws_api_gateway_rest_api.API.root_resource_id
  path_part   = "auth"
}

resource "aws_api_gateway_method" "Method" {
  rest_api_id   = aws_api_gateway_rest_api.API.id
  resource_id   = aws_api_gateway_resource.Resource.id
  http_method   = "POST"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.auth.id
}

resource "aws_api_gateway_integration" "Integration" {
  rest_api_id             = aws_api_gateway_rest_api.API.id
  resource_id             = aws_api_gateway_resource.Resource.id
  http_method             = aws_api_gateway_method.Method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_function.invoke_arn
}



resource "aws_lambda_permission" "apigw-lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name
  principal     = "apigateway.amazonaws.com"
  # source_arn    = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_region.current.id}:${aws_api_gateway_rest_api.API.id}/*/${aws_api_gateway_method.Method.http_method}${aws_api_gateway_resource.Resource.path}"
  # source_arn = "arn:aws:execute-api:*:*:${aws_api_gateway_rest_api.API.id}/*/${aws_api_gateway_method.Method.http_method}${aws_api_gateway_resource.Resource.path}"
  source_arn = "arn:${data.aws_partition.current.partition}:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.API.id}/*/${aws_api_gateway_method.Method.http_method}${aws_api_gateway_resource.Resource.path}"

  depends_on = [aws_api_gateway_integration.Integration]
}


resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.API.id
  resource_id = aws_api_gateway_resource.Resource.id
  http_method = aws_api_gateway_method.Method.http_method
  status_code = "200"
}

# resource "aws_api_gateway_integration_response" "Integration-Response" {
#   rest_api_id = aws_api_gateway_rest_api.API.id
#   resource_id = aws_api_gateway_resource.Resource.id
#   http_method = aws_api_gateway_method.Method.http_method
#   status_code = aws_api_gateway_method_response.response_200.status_code

#   depends_on = [
#     aws_api_gateway_integration.Integration
#   ]

#   response_templates = {
#     "application/xml" = <<EOF
# #set($inputRoot = $input.path('$'))
# <?xml version="1.0" encoding="UTF-8"?>
# <message>
#     $inputRoot.body
# </message>
# EOF
#   }
# }


# Deployment (no stage_name here in recent providers)
# resource "aws_api_gateway_deployment" "current" {
#   depends_on = [
#     aws_api_gateway_integration.Integration
#   ]
#   rest_api_id = aws_api_gateway_rest_api.API.id

#   # Optional: force a new deployment when things change
#   # triggers = {
#   #   redeploy = timestamp()
#   # }
# }

resource "aws_api_gateway_stage" "example" {
  rest_api_id   = aws_api_gateway_rest_api.API.id
  stage_name    = "example"
  deployment_id = aws_api_gateway_deployment.current.id
}

############################
# Authorizer
############################

resource "aws_api_gateway_authorizer" "auth" {
  name                             = "AuthToken"
  rest_api_id                      = aws_api_gateway_rest_api.API.id
  type                             = "TOKEN"
  identity_source                  = "method.request.header.Authorization"
  authorizer_uri                   = "arn:${data.aws_partition.current.partition}:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.api_gateway_authorizer.arn}/invocations"
  authorizer_result_ttl_in_seconds = 300
}

############################
# Any /api/v1/{proxy+} -> api-gw-lambda (CUSTOM authorizer)
############################

resource "aws_api_gateway_method" "proxy_any" {
  rest_api_id   = aws_api_gateway_rest_api.API.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.auth.id
}

# resource "aws_api_gateway_integration" "proxy_any" {
#   rest_api_id             = aws_api_gateway_rest_api.API.id
#   resource_id             = aws_api_gateway_resource.proxy.id
#   http_method             = aws_api_gateway_method.proxy_any.http_method
#   integration_http_method = "POST"
#   type                    = "AWS_PROXY"
#   uri                     = "arn:${data.aws_partition.current.partition}:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.lambda.arn}/invocations"
# }

# # Lambda permission for the handler (covers ANY /api/v1/*)
# resource "aws_lambda_permission" "allow_apigw_invoke_handler" {
#   statement_id  = "AllowExecutionFromAPIGatewayProxy"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.lambda.function_name
#   principal     = "apigateway.amazonaws.com"
#   source_arn    = "${aws_api_gateway_rest_api.API.execution_arn}/*/*/api/v1/*"
# }

############################
# POST /auth -> api-gw-lambda (NO auth)
############################

resource "aws_api_gateway_method" "auth_post" {
  rest_api_id   = aws_api_gateway_rest_api.API.id
  resource_id   = aws_api_gateway_resource.auth.id
  http_method   = "POST"
  authorization = "NONE"
}

# resource "aws_api_gateway_integration" "auth_post" {
#   rest_api_id             = aws_api_gateway_rest_api.API.id
#   resource_id             = aws_api_gateway_resource.auth.id
#   http_method             = aws_api_gateway_method.auth_post.http_method
#   integration_http_method = "POST"
#   type                    = "AWS_PROXY"
#   uri                     = "arn:${data.aws_partition.current.partition}:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.lambda.arn}/invocations"
# }

############################
# CORS (OPTIONS) for /, /api, /api/v1, /api/v1/admin, /api/v1/admin/users, /auth
############################

locals {
  cors_resources = {
    root  = aws_api_gateway_rest_api.API.root_resource_id
    api   = aws_api_gateway_resource.api.id
    v1    = aws_api_gateway_resource.v1.id
    admin = aws_api_gateway_resource.admin.id
    users = aws_api_gateway_resource.users.id
    auth  = aws_api_gateway_resource.auth.id
  }
}

resource "aws_api_gateway_method" "options" {
  for_each      = local.cors_resources
  rest_api_id   = aws_api_gateway_rest_api.API.id
  resource_id   = each.value
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options" {
  for_each    = local.cors_resources
  rest_api_id = aws_api_gateway_rest_api.API.id
  resource_id = each.value
  http_method = aws_api_gateway_method.options[each.key].http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options_200" {
  for_each        = local.cors_resources
  rest_api_id     = aws_api_gateway_rest_api.API.id
  resource_id     = each.value
  http_method     = aws_api_gateway_method.options[each.key].http_method
  status_code     = "200"
  response_models = { "application/json" = "Empty" }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "options_200" {
  for_each    = local.cors_resources
  rest_api_id = aws_api_gateway_rest_api.API.id
  resource_id = each.value
  http_method = aws_api_gateway_method.options[each.key].http_method
  status_code = aws_api_gateway_method_response.options_200[each.key].status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Authorization,Content-Type,X-Amz-Date,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,OPTIONS,PATCH'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

############################
# Deployment & Stage
############################

resource "aws_api_gateway_deployment" "current" {
  depends_on = [
    aws_api_gateway_integration.Integration,
    aws_api_gateway_method.Method,
    # aws_api_gateway_integration.proxy_any,
    # aws_api_gateway_integration.auth_post,
    aws_api_gateway_integration_response.options_200,
  ]
  rest_api_id = aws_api_gateway_rest_api.API.id

  # force a redeploy on changes
  triggers = { redeploy = timestamp() }
}

resource "aws_api_gateway_stage" "v1" {
  rest_api_id   = aws_api_gateway_rest_api.API.id
  stage_name    = "v1"
  deployment_id = aws_api_gateway_deployment.current.id
}

