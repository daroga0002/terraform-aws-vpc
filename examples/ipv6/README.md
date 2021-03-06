# VPC with IPv6 enabled

Configuration in this directory creates set of VPC resources with IPv6 enabled on VPC and subnets.

## Usage

To run this example you need to execute:

```bash
$ terraform init
$ terraform plan
$ terraform apply
```

Note that this example may create resources which can cost money (AWS Elastic IP, for example). Run `terraform destroy` when you don't need these resources.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.12.21 |
| aws | >= 2.70 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 2.70 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| vpc | ../.. |  |

## Resources

| Name |
|------|
| [aws_availability_zones](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) |

## Inputs

No input.

## Outputs

| Name | Description |
|------|-------------|
| ipv6\_association\_id | The association ID for the IPv6 CIDR block |
| ipv6\_cidr\_block | The IPv6 CIDR block |
| vpc\_id | The ID of the VPC |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
