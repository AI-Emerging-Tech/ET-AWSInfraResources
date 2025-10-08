##################################################################
# Create IAM user and policies for continuous deploy (CD) account
##################################################################
resource "aws_iam_user" "cd" {
  name = "devops-app-cd-user"
}

resource "aws_iam_access_key" "cd" {
  user = aws_iam_user.cd.name
}

#########################################################
# Policy for Terraform backend (S3 state + DynamoDB lock)
#########################################################
data "aws_iam_policy_document" "tf_backend" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${var.tf_state_bucket}",
      "arn:aws:s3:::${var.et_ai_lambda_function}"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
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

#########################################
# Combined deploy policy (Lambda/EC2/ECS/RDS/ELB)
#########################################
data "aws_iam_policy_document" "cd_deploy" {
  # Lambda
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

  # EC2 (networking primitives used by your TF)
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
      "ec2:DescribeSecurityGroupRules",
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

  # ECS
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

  # RDS
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
      "rds:AddTagsToResource",
      "rds:ModifyDBSubnetGroup"
    ]
    resources = ["*"]
  }

  # ELB
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

##################################
# S3 administrative policy (buckets/objects)
##################################
data "aws_iam_policy_document" "aws_s3_bucket" {
  statement {
    sid    = "S3BucketAdminForDeploy"
    effect = "Allow"
    actions = [
      "s3:*",
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
      "s3:GetBucketAcl",

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
# API Gateway administrative
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
# ECR push/pull policy
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
# EC2 (standalone policy) — kept for clarity
#########################
data "aws_iam_policy_document" "ec2" {
  statement {
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
      "ec2:DescribeSecurityGroupRules",
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
}

resource "aws_iam_policy" "ec2" {
  name        = "${aws_iam_user.cd.name}-ec2"
  description = "Allow user to manage EC2 resources."
  policy      = data.aws_iam_policy_document.ec2.json
}

resource "aws_iam_user_policy_attachment" "ec2" {
  user       = aws_iam_user.cd.name
  policy_arn = aws_iam_policy.ec2.arn
}

########################################
# Amplify minimal policy for CD user
########################################
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_iam_policy_document" "amplify_min" {
  statement {
    sid    = "AmplifyOnApp"
    effect = "Allow"
    actions = [
      "amplify:CreateApp",
      "amplify:UpdateApp",
      "amplify:DeleteApp",
      "amplify:GetApp",
      "amplify:GetArtifactUrl",
      "amplify:GenerateAccessLogs",
      "amplify:ListResourcesForWebACL",
      "amplify:GetWebACLForResource",
      "amplify:AssociateWebACL",
      "amplify:DisassociateWebACL",
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

  statement {
    sid       = "AmplifyListGlobal"
    effect    = "Allow"
    actions   = ["amplify:ListApps"]
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

###############################################################
# OpenSearch Serverless (AOSS) control-plane permissions (CI)
###############################################################
data "aws_iam_policy_document" "aoss_control_plane" {
  statement {
    sid    = "AossReadList"
    effect = "Allow"
    actions = [
      "aoss:ListCollections",
      "aoss:GetCollection",
      "aoss:BatchGetCollection",
      "aoss:ListSecurityPolicies",
      "aoss:GetSecurityPolicy",
      "aoss:ListAccessPolicies",
      "aoss:GetAccessPolicy",
      "aoss:ListVpcEndpoints",
      "aoss:BatchGetVpcEndpoint"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AossWriteAdmin"
    effect = "Allow"
    actions = [
      "aoss:CreateCollection",
      "aoss:UpdateCollection",
      "aoss:DeleteCollection",
      "aoss:CreateSecurityPolicy",
      "aoss:UpdateSecurityPolicy",
      "aoss:DeleteSecurityPolicy",
      "aoss:CreateAccessPolicy",
      "aoss:UpdateAccessPolicy",
      "aoss:DeleteAccessPolicy",
      "aoss:CreateVpcEndpoint",
      "aoss:UpdateVpcEndpoint",
      "aoss:DeleteVpcEndpoint",
      "aoss:TagResource",
      "aoss:UntagResource"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "aoss_control_plane" {
  name        = "${aws_iam_user.cd.name}-aoss-control-plane"
  description = "Control-plane permissions for provisioning AOSS collections, policies, and VPC endpoints"
  policy      = data.aws_iam_policy_document.aoss_control_plane.json
}

resource "aws_iam_user_policy_attachment" "cd_aoss_control_plane" {
  user       = aws_iam_user.cd.name
  policy_arn = aws_iam_policy.aoss_control_plane.arn
}

###############################################################
# Route53 permissions for AOSS VPCE private DNS (SINGLE COPY)
###############################################################
data "aws_iam_policy_document" "route53_for_aoss" {
  statement {
    sid    = "Route53PrivateDNSForAoss"
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:GetHostedZone",
      "route53:GetChange",
      "route53:ListHostedZones",
      "route53:ListHostedZonesByVPC",
      "route53:AssociateVPCWithHostedZone",
      "route53:DisassociateVPCFromHostedZone",
      "route53:CreateVPCAssociationAuthorization",
      "route53:DeleteVPCAssociationAuthorization"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "route53_for_aoss" {
  name        = "${aws_iam_user.cd.name}-route53-for-aoss"
  description = "Route53 permissions for OpenSearch Serverless VPC endpoints with private DNS"
  policy      = data.aws_iam_policy_document.route53_for_aoss.json
}

resource "aws_iam_user_policy_attachment" "cd_route53_for_aoss" {
  user       = aws_iam_user.cd.name
  policy_arn = aws_iam_policy.route53_for_aoss.arn
}

# OPTIONAL: If you move to a CMK for AOSS encryption, also grant KMS on that key
# and ensure the key policy trusts the AOSS service role.
# (example commented in previous messages)
