resource "aws_amplify_app" "et_ai_poc_portal" {
  name       = var.ui_app_name
  repository = var.cd_github_repository #This will be your reactjs project

  access_token = var.cd_github_access_token

  enable_branch_auto_build = true
  #build_spec               = null

  # The default build_spec added by the Amplify Console for React.
  # build_spec = <<-EOT
  #   version: 1
  #   frontend:
  #     phases:
  #       preBuild:
  #         commands:
  #           - npm ci --cache .npm --prefer-offline
  #       build:
  #         commands:
  #           - npm run build
  #     artifacts:
  #       baseDirectory: .next
  #       files:
  #         - '**/*'
  #     cache:
  #       paths:
  #         - .next/cache/**/*
  #         - .npm/**/*
  # EOT

  # The default rewrites and redirects added by the Amplify Console.
  # custom_rule {
  #   source = "/<*>"
  #   status = "404"
  #   target = "/index.html"
  # }
  # Normalize /index.html to /
  custom_rule {
    source = "/index.html"
    target = "/"
    status = "301"
  }


  #   environment_variables = {
  #     Name           = "hello-world"
  #     Provisioned_by = "Terraform"
  #   }
}

# resource "aws_amplify_webhook" "manual_kick" {
#   app_id      = aws_amplify_app.et_ai_poc_portal.id
#   branch_name = var.ui_branch_name
# }

resource "aws_amplify_branch" "amplify_branch" {
  app_id            = aws_amplify_app.et_ai_poc_portal.id
  branch_name       = var.ui_branch_name
  enable_auto_build = true
}

# resource "aws_amplify_domain_association" "domain_association" {
#   app_id                = aws_amplify_app.et_ai_poc_portal.id
#   domain_name           = var.domain_name
#   wait_for_verification = false

#   sub_domain {
#     branch_name = aws_amplify_branch.amplify_branch.branch_name
#     prefix      = var.ui_branch_name
#   }

# }