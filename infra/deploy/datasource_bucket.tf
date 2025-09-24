# datasource_bucket.tf

resource "random_id" "s3_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "data_source" {
  bucket = "data-source-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.id}-${random_id.s3_suffix.hex}"
  tags = {
    Name = "${local.prefix}-data-source"
  }
}


# resource "aws_vpc_endpoint" "s3_gateway" {
#   vpc_id       = aws_vpc.main.id
#   service_name = "com.amazonaws.${data.aws_region.current.region}.s3"
#   route_table_ids = [
#     aws_vpc.main.default_route_table_id
#   ]
#   vpc_endpoint_type = "Gateway"

#   policy = <<POLICY
# {
#   "Version": "2008-10-17",
#   "Statement": [
#     {
#       "Action": "*",
#       "Effect": "Allow",
#       "Resource": "*",
#       "Principal": "*"
#     }
#   ]
# }
# POLICY
# }

resource "aws_s3_bucket_public_access_block" "data_source" {
  bucket                  = aws_s3_bucket.data_source.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# resource "aws_vpc_endpoint" "s3_interface" {
#   depends_on          = [aws_vpc_endpoint.s3_gateway]
#   vpc_id              = aws_vpc.main.id
#   service_name        = "com.amazonaws.${data.aws_region.current.region}.s3"
#   private_dns_enabled = true
#   vpc_endpoint_type   = "Interface"
#   security_group_ids  = [aws_security_group.rds.id]

#   policy = <<POLICY
# {
#   "Version": "2008-10-17",
#   "Statement": [
#     {
#       "Action": "*",
#       "Effect": "Allow",
#       "Resource": "*",
#       "Principal": "*"
#     }
#   ]
# }
# POLICY
# }