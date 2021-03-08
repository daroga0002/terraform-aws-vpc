provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source = "../../"

  name = "prod"

  cidr = "10.0.0.0/16"

  azs                    = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets        = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets         = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  create_igw             = true
  create_firewall        = true
  firewall_subnets       = ["10.0.11.0/24", "10.0.21.0/24", "10.0.31.0/24"]
  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true
  enable_firewall_log    = false
  tags = {
    Owner       = "user"
    Environment = "staging"
  }
}
