provider "aws" {
  region = "us-east-1"
}


locals {
  subnets            = [for cidr_block in cidrsubnets("10.0.0.0/16", 2, 2, 2) : cidrsubnets(cidr_block, 1, 3, 3, 3, 3)]
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 3)
  common_tags        = { temp = "yes" }
}

data "aws_elb_service_account" "main" {}

data "aws_availability_zones" "available" {

}

resource "aws_s3_bucket" "vpc_flow_logs" {
  bucket_prefix = "vpc-flow-logs"
  tags = merge({
    Name            = "vpc-flow-logs-s3-bucket",
    description     = "AWS Flow logs from network",
    technical_owner = "Platform",
    business_owner  = "Platform"
  }, local.common_tags)

  lifecycle_rule {
    enabled = true
    noncurrent_version_expiration {
      days = "7"
    }
  }
}

resource "aws_s3_bucket_policy" "s3_bucket_policy" {
  bucket = aws_s3_bucket.vpc_flow_logs.id
  policy = data.aws_iam_policy_document.flow_log_s3.json
}

data "aws_iam_policy_document" "flow_log_s3" {
  statement {
    sid = "AWSLogDeliveryWrite"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    effect = "Allow"

    actions = [
      "s3:PutObject",
    ]

    resources = ["${aws_s3_bucket.vpc_flow_logs.arn}/AWSLogs/*"]
  }

  statement {
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.vpc_flow_logs.arn}/*"]

    principals {
      identifiers = [data.aws_elb_service_account.main.arn]
      type        = "AWS"
    }
  }

  statement {
    sid = "AWSLogDeliveryAclCheck"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    effect = "Allow"
    actions = [
      "s3:GetBucketAcl",
    ]
    resources = [aws_s3_bucket.vpc_flow_logs.arn]
  }

  statement {
    sid = "AWSALBLogs"
    principals {
      type        = "Service"
      identifiers = ["logdelivery.elb.amazonaws.com"]
    }
    effect = "Allow"
    actions = [
      "s3:PutObject",
    ]
    resources = ["${aws_s3_bucket.vpc_flow_logs.arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"

      values = [
        "bucket-owner-full-control"
      ]
    }
  }

  statement {
    sid = "AWSCloudTrailAclCheck20150319"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    effect = "Allow"
    actions = [
      "s3:GetBucketAcl",
    ]
    resources = [aws_s3_bucket.vpc_flow_logs.arn]
  }

  statement {
    sid = "AWSCloudTrailWrite20150319"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    effect = "Allow"
    actions = [
      "s3:PutObject",
    ]
    resources = ["${aws_s3_bucket.vpc_flow_logs.arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"

      values = [
        "bucket-owner-full-control"
      ]
    }
  }
}

module "vpc" {
  # https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/2.70.0
  source              = "../.."
  name                = "temp"
  cidr                = "10.0.0.0/16"
  enable_flow_log     = true
  create_firewall     = true
  firewall_subnets    = local.subnets[*][4]
  enable_firewall_log = true

  firewall_log_destination_type = "S3"
  firewall_log_destination_name = aws_s3_bucket.vpc_flow_logs.id

  flow_log_destination_type = "s3"
  flow_log_destination_arn  = aws_s3_bucket.vpc_flow_logs.arn
  vpc_flow_log_tags = {
    Name            = "vpc-flow-logs-s3",
    description     = "AWS VPC Flow logs",
    technical_owner = "Platform",
    business_owner  = "Platform"
  }
  azs                             = local.availability_zones
  private_subnets                 = local.subnets[*][0]
  public_subnets                  = local.subnets[*][1]
  database_subnets                = local.subnets[*][2]
  elasticache_subnets             = local.subnets[*][3]
  enable_nat_gateway              = true
  single_nat_gateway              = false
  one_nat_gateway_per_az          = true
  public_subnet_tags              = { "network" = "public" }
  private_subnet_tags             = { "network" = "private" }
  database_subnet_tags            = { "network" = "database" }
  elasticache_subnet_tags         = { "network" = "elasticache" }
  create_database_subnet_group    = true
  create_elasticache_subnet_group = true
  enable_dns_hostnames            = true
  enable_dns_support              = true
  enable_s3_endpoint              = true
  enable_dynamodb_endpoint        = true
  tags = merge(local.common_tags, {
    module          = "vpc",
    description     = "AWS VPC and other network objects",
    technical_owner = "Platform",
    business_owner  = "Platform"
    }
  )
}