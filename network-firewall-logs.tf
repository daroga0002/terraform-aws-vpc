locals {
  enable_firewall_log = var.create_firewall && var.enable_firewall_log

  firewall_log_destination = var.firewall_log_destination_type == "S3" ? {
    bucketName = var.firewall_log_destination_arn,
    prefix     = "/firewall"
    } : var.firewall_log_destination_type == "KinesisDataFirehose" ? {
    deliveryStream = var.firewall_log_destination_arn
    } : {
    logGroup = var.firewall_log_destination_arn
  }
}

resource "aws_networkfirewall_logging_configuration" "firewall" {
  count        = local.enable_firewall_log ? 1 : 0
  firewall_arn = aws_networkfirewall_firewall.firewall[0].arn
  logging_configuration {
    log_destination_config {
      log_destination      = local.firewall_log_destination
      log_destination_type = var.firewall_log_destination_type
      log_type             = var.firewall_log_traffic_type
    }
  }
}


