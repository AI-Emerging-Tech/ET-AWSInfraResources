##################################################################
# Create IAM user and policies for continuous deploy(CD) account #
##################################################################
resource "aws_iam_user" "cd" {
  name = "devops-app-cd-user"
}
resource "aws_iam_access_key" "cd" {
  user = aws_iam_user.cd.name
}


#########################################################
# Policy for Teraform backend to S3 and DynamoDB access #
#########################################################

data "aws_iam_policy_document" "tf_backend" {
  statement {
    effect  = "Allow"
    actions = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.tf_state_bucket}",
    "arn:aws:s3:::${var.et_ai_lambda_function}"]
  }

  statement {
    effect  = "Allow"
    actions = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = [
      "arn:aws:s3:::${var.tf_state_bucket}/tf-state-deploy",
      "arn:aws:s3:::${var.tf_state_bucket}/tf-state-deploy/*",
      "arn:aws:s3:::${var.tf_state_bucket}/tf-state-deploy-env/*",
      "arn:aws:s3:::${var.et_ai_lambda_function}/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    resources = ["arn:aws:dynamodb:*:*:table/${var.tf_state_lock_table}"]
  }
}

resource "aws_iam_policy" "tf_backend" {
  name        = "${aws_iam_user.cd.name}-tf-s3-dynamodb"
  description = "Allow user to use S3 and DynamoDB for TF backend resources"
  policy      = data.aws_iam_policy_document.tf_backend.json
}

resource "aws_iam_user_policy_attachment" "tf_backend" {
  user       = aws_iam_user.cd.name
  policy_arn = aws_iam_policy.tf_backend.arn
}

# ############################
# # Policy for Lambda Access #
# ############################

# data "aws_iam_policy_document" "lambda" {
#   statement {
#     effect = "Allow"
#     actions = [
#       "lambda:CreateFunction",
#       "lambda:UpdateFunctionCode",
#       "lambda:UpdateFunctionConfiguration",
#       "lambda:DeleteFunction",
#       "lambda:GetFunction",
#       "lambda:ListFunctions",
#       "lambda:AddPermission",
#       "lambda:RemovePermission",
#       "lambda:InvokeFunction",
#       "lambda:TagResource",
#       "lambda:UntagResource",
#       "lambda:ListTags",
#       "lambda:ListVersionsByFunction",
#       "lambda:ListVersionsByFunction",
#       "lambda:GetFunctionCodeSigningConfig",
#       "lambda:GetPolicy",
#       "lambda:GetFunctionUrlConfig",
#       "lambda:ListAliases"
#     ]
#     resources = ["*"]
#   }

#   # Optional: For managing Lambda permissions
#   statement {
#     effect = "Allow"
#     actions = [
#       "iam:PassRole"
#     ]
#     resources = ["arn:aws:iam::*:role/*"]
#   }
# }

# resource "aws_iam_policy" "lambda" {
#   name        = "${aws_iam_user.cd.name}-lambda"
#   description = "Allow user to manage Lambda resources."
#   policy      = data.aws_iam_policy_document.lambda.json
# }

# resource "aws_iam_user_policy_attachment" "lambda" {
#   user       = aws_iam_user.cd.name
#   policy_arn = aws_iam_policy.lambda.arn
# }

data "aws_iam_policy_document" "cd_deploy" {
  statement {
    sid    = "LambdaAccess"
    effect = "Allow"
    actions = [
      "lambda:CreateFunction",
      "lambda:UpdateFunctionCode",
      "lambda:UpdateFunctionConfiguration",
      "lambda:DeleteFunction",
      "lambda:GetFunction",
      "lambda:ListFunctions",
      "lambda:AddPermission",
      "lambda:RemovePermission",
      "lambda:InvokeFunction",
      "lambda:TagResource",
      "lambda:UntagResource",
      "lambda:ListTags",
      "lambda:ListVersionsByFunction",
      "lambda:GetFunctionCodeSigningConfig",
      "lambda:GetPolicy",
      "lambda:GetFunctionUrlConfig",
      "lambda:ListAliases"
    ]
    resources = ["*"]
  }

  statement {
    sid       = "LambdaIAMPassRole"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = ["arn:aws:iam::*:role/*"]
  }

  statement {
    sid    = "EC2Access"
    effect = "Allow"
    actions = [
      "ec2:DescribeVpcs",
      "ec2:CreateTags",
      "ec2:CreateVpc",
      "ec2:DeleteVpc",
      "ec2:DescribeSecurityGroups",
      "ec2:DeleteSubnet",
      "ec2:DeleteSecurityGroup",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DetachInternetGateway",
      "ec2:DescribeInternetGateways",
      "ec2:DeleteInternetGateway",
      "ec2:DetachNetworkInterface",
      "ec2:DescribeVpcEndpoints",
      "ec2:DescribeRouteTables",
      "ec2:DeleteRouteTable",
      "ec2:DeleteVpcEndpoints",
      "ec2:DisassociateRouteTable",
      "ec2:DeleteRoute",
      "ec2:DescribePrefixLists",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcAttribute",
      "ec2:DescribeNetworkAcls",
      "ec2:AssociateRouteTable",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:CreateSecurityGroup",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:CreateVpcEndpoint",
      "ec2:ModifySubnetAttribute",
      "ec2:CreateSubnet",
      "ec2:CreateRoute",
      "ec2:CreateRouteTable",
      "ec2:CreateInternetGateway",
      "ec2:AttachInternetGateway",
      "ec2:ModifyVpcAttribute",
      "ec2:RevokeSecurityGroupIngress"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ECSAccess"
    effect = "Allow"
    actions = [
      "ecs:DescribeClusters",
      "ecs:DeregisterTaskDefinition",
      "ecs:DeleteCluster",
      "ecs:DescribeServices",
      "ecs:UpdateService",
      "ecs:DeleteService",
      "ecs:DescribeTaskDefinition",
      "ecs:CreateService",
      "ecs:RegisterTaskDefinition",
      "ecs:CreateCluster",
      "ecs:UpdateCluster",
      "ecs:TagResource"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "RDSAccess"
    effect = "Allow"
    actions = [
      "rds:DescribeDBSubnetGroups",
      "rds:DescribeDBInstances",
      "rds:CreateDBSubnetGroup",
      "rds:DeleteDBSubnetGroup",
      "rds:CreateDBInstance",
      "rds:DeleteDBInstance",
      "rds:ListTagsForResource",
      "rds:ModifyDBInstance",
      "rds:AddTagsToResource"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ELBAccess"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeListenerAttributes",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetGroupAttributes",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:SetSecurityGroups",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:ModifyTargetGroupAttributes",
      "elasticloadbalancing:CreateTargetGroup",
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:DescribeTags",
      "elasticloadbalancing:ModifyListener"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "cd_deploy" {
  name        = "${aws_iam_user.cd.name}-deploy"
  description = "Combined policy for Lambda, EC2, ECS, RDS, ELB access"
  policy      = data.aws_iam_policy_document.cd_deploy.json
}

resource "aws_iam_user_policy_attachment" "cd_deploy" {
  user       = aws_iam_user.cd.name
  policy_arn = aws_iam_policy.cd_deploy.arn
}



#########################################################
# Policy for S3 bucket access #
#########################################################

data "aws_iam_policy_document" "aws_s3_bucket" {
  statement {
    sid    = "S3BucketAdminForDeploy"
    effect = "Allow"
    actions = [
      "s3:CreateBucket",
      "s3:DeleteBucket",
      "s3:ListAllMyBuckets",

      # bucket reads/writes Terraform does during create/read
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:GetBucketTagging",
      "s3:PutBucketTagging",
      "s3:GetBucketPolicy",
      "s3:PutBucketPolicy",
      "s3:GetBucketVersioning",
      "s3:PutBucketVersioning",

      # encryption + access block + ownership controls
      "s3:GetEncryptionConfiguration",
      "s3:PutEncryptionConfiguration",
      "s3:GetBucketPublicAccessBlock",
      "s3:PutBucketPublicAccessBlock",
      "s3:GetBucketOwnershipControls",
      "s3:PutBucketOwnershipControls"
    ]
    resources = ["arn:aws:s3:::*"]
  }

  # (Optional) object-level access if your TF also uploads/reads objects
  statement {
    sid    = "S3ObjectRWForDeploy"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectTagging",
      "s3:PutObject",
      "s3:PutObjectTagging",
      "s3:DeleteObject"
    ]
    resources = ["arn:aws:s3:::*/*"]
  }
}

resource "aws_iam_policy" "aws_s3_bucket" {
  name        = "${aws_iam_user.cd.name}-aws-s3-bucket"
  description = "Allow user to manage S3 resources."
  policy      = data.aws_iam_policy_document.aws_s3_bucket.json
}

resource "aws_iam_user_policy_attachment" "aws_s3_bucket" {
  user       = aws_iam_user.cd.name
  policy_arn = aws_iam_policy.aws_s3_bucket.arn
}




###############################
# Policy for API Gateway Access
###############################

data "aws_iam_policy_document" "apigateway" {
  statement {
    effect = "Allow"
    actions = [
      "apigateway:GET",
      "apigateway:POST",
      "apigateway:PUT",
      "apigateway:DELETE",
      "apigateway:PATCH"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "apigateway" {
  name        = "${aws_iam_user.cd.name}-apigateway"
  description = "Allow user to manage API Gateway resources."
  policy      = data.aws_iam_policy_document.apigateway.json
}

resource "aws_iam_user_policy_attachment" "apigateway" {
  user       = aws_iam_user.cd.name
  policy_arn = aws_iam_policy.apigateway.arn
}

#########################
# Policy for ECR access #
#########################


data "aws_iam_policy_document" "ecr" {
  statement {
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:CompleteLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:InitiateLayerUpload",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage"
    ]
    resources = [
      aws_ecr_repository.app.arn,
      aws_ecr_repository.proxy.arn,
      aws_ecr_repository.tools.arn
    ]
  }
}

resource "aws_iam_policy" "ecr" {
  name        = "${aws_iam_user.cd.name}-ecr"
  description = "Allow user to manage ECR resources"
  policy      = data.aws_iam_policy_document.ecr.json
}

resource "aws_iam_user_policy_attachment" "ecr" {
  user       = aws_iam_user.cd.name
  policy_arn = aws_iam_policy.ecr.arn
}

#########################
# Policy for EC2 access #
#########################

# data "aws_iam_policy_document" "ec2" {
#   statement {
#     effect = "Allow"
#     actions = [
#       "ec2:DescribeVpcs",
#       "ec2:CreateTags",
#       "ec2:CreateVpc",
#       "ec2:DeleteVpc",
#       "ec2:DescribeSecurityGroups",
#       "ec2:DeleteSubnet",
#       "ec2:DeleteSecurityGroup",
#       "ec2:DescribeNetworkInterfaces",
#       "ec2:DetachInternetGateway",
#       "ec2:DescribeInternetGateways",
#       "ec2:DeleteInternetGateway",
#       "ec2:DetachNetworkInterface",
#       "ec2:DescribeVpcEndpoints",
#       "ec2:DescribeRouteTables",
#       "ec2:DeleteRouteTable",
#       "ec2:DeleteVpcEndpoints",
#       "ec2:DisassociateRouteTable",
#       "ec2:DeleteRoute",
#       "ec2:DescribePrefixLists",
#       "ec2:DescribeSubnets",
#       "ec2:DescribeVpcAttribute",
#       "ec2:DescribeNetworkAcls",
#       "ec2:AssociateRouteTable",
#       "ec2:AuthorizeSecurityGroupIngress",
#       "ec2:RevokeSecurityGroupEgress",
#       "ec2:CreateSecurityGroup",
#       "ec2:AuthorizeSecurityGroupEgress",
#       "ec2:CreateVpcEndpoint",
#       "ec2:ModifySubnetAttribute",
#       "ec2:CreateSubnet",
#       "ec2:CreateRoute",
#       "ec2:CreateRouteTable",
#       "ec2:CreateInternetGateway",
#       "ec2:AttachInternetGateway",
#       "ec2:ModifyVpcAttribute",
#       "ec2:RevokeSecurityGroupIngress",
#     ]
#     resources = ["*"]
#   }
# }

# resource "aws_iam_policy" "ec2" {
#   name        = "${aws_iam_user.cd.name}-ec2"
#   description = "Allow user to manage EC2 resources."
#   policy      = data.aws_iam_policy_document.ec2.json
# }

# resource "aws_iam_user_policy_attachment" "ec2" {
#   user       = aws_iam_user.cd.name
#   policy_arn = aws_iam_policy.ec2.arn
# }

# #########################
# # Policy for RDS access #
# #########################

# data "aws_iam_policy_document" "rds" {
#   statement {
#     effect = "Allow"
#     actions = [
#       "rds:DescribeDBSubnetGroups",
#       "rds:DescribeDBInstances",
#       "rds:CreateDBSubnetGroup",
#       "rds:DeleteDBSubnetGroup",
#       "rds:CreateDBInstance",
#       "rds:DeleteDBInstance",
#       "rds:ListTagsForResource",
#       "rds:ModifyDBInstance",
#       "rds:AddTagsToResource"
#     ]
#     resources = ["*"]
#   }
# }

# resource "aws_iam_policy" "rds" {
#   name        = "${aws_iam_user.cd.name}-rds"
#   description = "Allow user to manage RDS resources."
#   policy      = data.aws_iam_policy_document.rds.json
# }

# resource "aws_iam_user_policy_attachment" "rds" {
#   user       = aws_iam_user.cd.name
#   policy_arn = aws_iam_policy.rds.arn
# }

# #########################
# # Policy for ECS access #
# #########################

# data "aws_iam_policy_document" "ecs" {
#   statement {
#     effect = "Allow"
#     actions = [
#       "ecs:DescribeClusters",
#       "ecs:DeregisterTaskDefinition",
#       "ecs:DeleteCluster",
#       "ecs:DescribeServices",
#       "ecs:UpdateService",
#       "ecs:DeleteService",
#       "ecs:DescribeTaskDefinition",
#       "ecs:CreateService",
#       "ecs:RegisterTaskDefinition",
#       "ecs:CreateCluster",
#       "ecs:UpdateCluster",
#       "ecs:TagResource",
#     ]
#     resources = ["*"]
#   }
# }

# resource "aws_iam_policy" "ecs" {
#   name        = "${aws_iam_user.cd.name}-ecs"
#   description = "Allow user to manage ECS resources."
#   policy      = data.aws_iam_policy_document.ecs.json
# }

# resource "aws_iam_user_policy_attachment" "ecs" {
#   user       = aws_iam_user.cd.name
#   policy_arn = aws_iam_policy.ecs.arn
# }

# #########################
# # Policy for IAM access #
# #########################

data "aws_iam_policy_document" "iam" {
  statement {
    effect = "Allow"
    actions = [
      "iam:ListInstanceProfilesForRole",
      "iam:ListAttachedRolePolicies",
      "iam:DeleteRole",
      "iam:ListPolicyVersions",
      "iam:DeletePolicy",
      "iam:DetachRolePolicy",
      "iam:ListRolePolicies",
      "iam:GetRole",
      "iam:GetPolicyVersion",
      "iam:GetPolicy",
      "iam:CreateRole",
      "iam:CreatePolicy",
      "iam:AttachRolePolicy",
      "iam:TagRole",
      "iam:TagPolicy",
      "iam:PassRole",
      "iam:PutRolePolicy",
      "iam:GetRolePolicy",
      "iam:DeleteRolePolicy",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "iam" {
  name        = "${aws_iam_user.cd.name}-iam"
  description = "Allow user to manage IAM resources."
  policy      = data.aws_iam_policy_document.iam.json
}

resource "aws_iam_user_policy_attachment" "iam" {
  user       = aws_iam_user.cd.name
  policy_arn = aws_iam_policy.iam.arn
}


# ################################
# # Policy for CloudWatch access #
# ################################

data "aws_iam_policy_document" "logs" {
  statement {
    effect = "Allow"
    actions = [
      "logs:DeleteLogGroup",
      "logs:DescribeLogStreams",
      "logs:GetLogEvents",
      "logs:FilterLogEvents",
      "logs:DescribeLogGroups",
      "logs:CreateLogGroup",
      "logs:TagResource",
      "logs:ListTagsForResource",
      "logs:ListTagsLogGroup"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "logs" {
  name        = "${aws_iam_user.cd.name}-logs"
  description = "Allow user to manage CloudWatch resources."
  policy      = data.aws_iam_policy_document.logs.json
}

resource "aws_iam_user_policy_attachment" "logs" {
  user       = aws_iam_user.cd.name
  policy_arn = aws_iam_policy.logs.arn
}

# #########################
# # Policy for ELB access #
# #########################

# data "aws_iam_policy_document" "elb" {
#   statement {
#     effect = "Allow"
#     actions = [
#       "elasticloadbalancing:DeleteLoadBalancer",
#       "elasticloadbalancing:DeleteTargetGroup",
#       "elasticloadbalancing:DeleteListener",
#       "elasticloadbalancing:DescribeListeners",
#       "elasticloadbalancing:DescribeListenerAttributes",
#       "elasticloadbalancing:DescribeLoadBalancerAttributes",
#       "elasticloadbalancing:DescribeTargetGroups",
#       "elasticloadbalancing:DescribeTargetGroupAttributes",
#       "elasticloadbalancing:DescribeLoadBalancers",
#       "elasticloadbalancing:CreateListener",
#       "elasticloadbalancing:SetSecurityGroups",
#       "elasticloadbalancing:ModifyLoadBalancerAttributes",
#       "elasticloadbalancing:CreateLoadBalancer",
#       "elasticloadbalancing:ModifyTargetGroupAttributes",
#       "elasticloadbalancing:CreateTargetGroup",
#       "elasticloadbalancing:AddTags",
#       "elasticloadbalancing:DescribeTags",
#       "elasticloadbalancing:ModifyListener"
#     ]
#     resources = ["*"]
#   }
# }

# resource "aws_iam_policy" "elb" {
#   name        = "${aws_iam_user.cd.name}-elb"
#   description = "Allow user to manage ELB resources."
#   policy      = data.aws_iam_policy_document.elb.json
# }

# resource "aws_iam_user_policy_attachment" "elb" {
#   user       = aws_iam_user.cd.name
#   policy_arn = aws_iam_policy.elb.arn
# }

########################################
# Amplify permissions for CD IAM user  #
########################################

# Minimal, least-privilege set for Amplify App + branches/domains/webhooks.
# Notes:
# - Some actions (e.g., ListApps) don't support resource-level ARNs and must use "*".
# - Tagging actions must include all supported resource types (apps, branches, domains, webhooks).

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_iam_policy_document" "amplify_min" {
  # Actions that require specific resource ARNs
  statement {
    sid    = "AmplifyOnApp"
    effect = "Allow"
    actions = [
      "amplify:CreateApp",
      "amplify:UpdateApp",
      "amplify:DeleteApp",
      "amplify:GetApp",
      "amplify:GetArtifactUrl",     # used by deployments
      "amplify:GenerateAccessLogs", # optional but handy
      "amplify:ListResourcesForWebACL",
      "amplify:GetWebACLForResource",
      "amplify:AssociateWebACL",
      "amplify:DisassociateWebACL",
      # Tagging on app resources
      "amplify:TagResource",
      "amplify:UntagResource",
      "amplify:ListTagsForResource"
    ]
    resources = [
      "arn:aws:amplify:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:apps/*"
    ]
  }

  statement {
    sid    = "AmplifyOnBranchesDomainsJobsWebhooks"
    effect = "Allow"
    actions = [
      "amplify:CreateBranch",
      "amplify:UpdateBranch",
      "amplify:DeleteBranch",
      "amplify:GetBranch",
      "amplify:ListBranches",

      "amplify:CreateDomainAssociation",
      "amplify:UpdateDomainAssociation",
      "amplify:DeleteDomainAssociation",
      "amplify:GetDomainAssociation",
      "amplify:ListDomainAssociations",

      "amplify:CreateDeployment",
      "amplify:StartDeployment",
      "amplify:StartJob",
      "amplify:StopJob",
      "amplify:GetJob",
      "amplify:ListJobs",

      "amplify:CreateWebHook",
      "amplify:UpdateWebHook",
      "amplify:DeleteWebHook",
      "amplify:GetWebHook",
      "amplify:ListWebHooks",

      # Tagging across all supported resource types
      "amplify:TagResource",
      "amplify:UntagResource",
      "amplify:ListTagsForResource"
    ]
    resources = [
      "arn:aws:amplify:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:apps/*/branches/*",
      "arn:aws:amplify:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:apps/*/domains/*",
      "arn:aws:amplify:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:apps/*/branches/*/jobs/*",
      "arn:aws:amplify:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:webhooks/*"
    ]
  }

  # Actions that require "*" (no resource-level permission supported)
  statement {
    sid    = "AmplifyListGlobal"
    effect = "Allow"
    actions = [
      "amplify:ListApps"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "amplify_min" {
  name   = "devops-app-cd-amplify-min"
  policy = data.aws_iam_policy_document.amplify_min.json
}

resource "aws_iam_user_policy" "cd_amplify_min_inline" {
  name   = "devops-app-cd-amplify-min-inline"
  user   = aws_iam_user.cd.name
  policy = data.aws_iam_policy_document.amplify_min.json
}


# #########################
# # Policy for EFS access #
# #########################

# data "aws_iam_policy_document" "efs" {
#   statement {
#     effect = "Allow"
#     actions = [
#       "elasticfilesystem:DescribeFileSystems",
#       "elasticfilesystem:DescribeAccessPoints",
#       "elasticfilesystem:DeleteFileSystem",
#       "elasticfilesystem:DeleteAccessPoint",
#       "elasticfilesystem:DescribeMountTargets",
#       "elasticfilesystem:DeleteMountTarget",
#       "elasticfilesystem:DescribeMountTargetSecurityGroups",
#       "elasticfilesystem:DescribeLifecycleConfiguration",
#       "elasticfilesystem:CreateMountTarget",
#       "elasticfilesystem:CreateAccessPoint",
#       "elasticfilesystem:CreateFileSystem",
#       "elasticfilesystem:TagResource",
#     ]
#     resources = ["*"]
#   }
# }

# resource "aws_iam_policy" "efs" {
#   name        = "${aws_iam_user.cd.name}-efs"
#   description = "Allow user to manage EFS resources."
#   policy      = data.aws_iam_policy_document.efs.json
# }

# resource "aws_iam_user_policy_attachment" "efs" {
#   user       = aws_iam_user.cd.name
#   policy_arn = aws_iam_policy.efs.arn
# }


# #############################
# # Policy for Route53 access #
# #############################

# data "aws_iam_policy_document" "route53" {
#   statement {
#     effect = "Allow"
#     actions = [
#       "route53:ListHostedZones",
#       "route53:ListHostedZones",
#       "route53:ChangeTagsForResource",
#       "route53:GetHostedZone",
#       "route53:ListTagsForResource",
#       "route53:ChangeResourceRecordSets",
#       "route53:GetChange",
#       "route53:ListResourceRecordSets",
#       "acm:RequestCertificate",
#       "acm:AddTagsToCertificate",
#       "acm:DescribeCertificate",
#       "acm:ListTagsForCertificate",
#       "acm:DeleteCertificate",
#       "acm:CreateCertificate"
#     ]
#     resources = ["*"]
#   }
# }

# resource "aws_iam_policy" "route53" {
#   name        = "${aws_iam_user.cd.name}-route53"
#   description = "Allow user to manage Route53 resources."
#   policy      = data.aws_iam_policy_document.route53.json
# }

# resource "aws_iam_user_policy_attachment" "route53" {
#   user       = aws_iam_user.cd.name
#   policy_arn = aws_iam_policy.route53.arn
# }