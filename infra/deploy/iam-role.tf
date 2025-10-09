data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam-role" {
  name               = "iam-role-lambda-api-gateway"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}
# Full-access AOSS Role (for admins, power users, or service integrations)
data "aws_iam_policy_document" "aoss_full_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["aoss.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "aoss_full_role" {
  name               = "${var.prefix}-${terraform.workspace}-aoss-full-role"
  assume_role_policy = data.aws_iam_policy_document.aoss_full_assume_role.json

  tags = {
    Project     = var.project
    Environment = terraform.workspace
    Contact     = var.contact
  }
}

