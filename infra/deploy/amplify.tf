resource "aws_amplify_app" "et_ai_poc_portal" {
  name         = var.ui_app_name
  repository   = var.cd_github_repository # points at your UI repo
  access_token = var.cd_github_access_token

  # IMPORTANT: SSR needs WEB_COMPUTE (not WEB)
  platform = "WEB_COMPUTE"

  enable_branch_auto_build = true

  # Recommended build spec for Next.js SSR
  build_spec = <<-EOT
    version: 1
    frontend:
      phases:
        preBuild:
          commands:
            - npm ci
        build:
          commands:
            - npm run build
      artifacts:
        baseDirectory: .next
        files:
          - '**/*'
      cache:
        paths:
          - node_modules/**/*
  EOT

  # Normalize old bookmarks /index.html -> /
  custom_rule {
    source = "/index.html"
    target = "/"
    status = "301"
  }

  # Helpful to pin Node during build (18 or 20 are fine)
  environment_variables = {
    NODE_VERSION = "20"
    # If your NextAuth or app needs env at APP level, add here or on the branch
    # NEXTAUTH_URL = "https://${var.ui_branch_name}.${aws_amplify_app.et_ai_poc_portal.default_domain}/"
  }
  #prevent accidental deletion during terraform destroy
  # lifecycle {
  #   prevent_destroy = true
  # }
}

resource "aws_amplify_branch" "amplify_branch" {
  app_id            = aws_amplify_app.et_ai_poc_portal.id
  branch_name       = var.ui_branch_name
  enable_auto_build = true

  # Optional: per-branch env vars (secrets should be set in Amplify Console or via SSM)
  # environment_variables = {
  #   NEXTAUTH_URL = "https://${var.ui_branch_name}.${aws_amplify_app.et_ai_poc_portal.default_domain}/"
  # }
}
