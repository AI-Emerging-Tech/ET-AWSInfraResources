resource "aws_iam_role_policy" "iam-policy" {
  name   = "cloudwatch-policy"
  role   = aws_iam_role.iam-role.id
  policy = file("${path.module}/iam-policy.json")
}
# Only if your authorizer actually touches DynamoDB. Keep using your single Lambda role.
# OPTIONAL: allow authorizer to read a users table
data "aws_iam_policy_document" "authorizer_ddb" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:Query"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${var.aws_dynamodb_table}"
    ]
  }
}

resource "aws_iam_role_policy" "authorizer_ddb" {
  count  = var.aws_dynamodb_table == "" ? 0 : 1
  name   = "authorizer-ddb-read"
  role   = aws_iam_role.iam-role.id
  policy = data.aws_iam_policy_document.authorizer_ddb.json
}
