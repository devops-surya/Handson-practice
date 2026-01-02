# VPC Module Usage Example

This directory demonstrates how to use the VPC Terraform module.

## Structure

```
vpcmodule-usage/
├── provider.tf          # Terraform and AWS provider configuration
├── main.tf              # Main configuration with module call
├── variables.tf         # Input variables
├── outputs.tf           # Output values from module
├── terraform.tfvars.example  # Example variable values
└── README.md            # This file
```

## Quick Start

### 1. Copy the example variables file

```bash
cp terraform.tfvars.example terraform.tfvars
```

### 2. Edit `terraform.tfvars` with your values

```hcl
aws_region   = "us-east-1"
project_name = "my-company"
environment  = "production"

vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
```

### 3. Initialize Terraform

```bash
terraform init
```

This will download the AWS provider and initialize the module.

### 4. Review the plan

```bash
terraform plan
```

### 5. Apply the configuration

```bash
terraform apply
```

### 6. View outputs

```bash
terraform output
```

## Module Usage

The provider is configured in `provider.tf` and the module is called in `main.tf`:

```hcl
module "vpc" {
  source = "../vpc-module"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}
```

## Accessing Module Outputs

All module outputs are exposed through `outputs.tf`. For example:

```hcl
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}
```

## Using Module Outputs in Other Resources

You can use module outputs to create other resources:

```hcl
# Example: Create an EC2 instance in a public subnet
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  subnet_id     = module.vpc.public_subnet_ids[0]

  tags = {
    Name = "web-server"
  }
}
```

## Customization

### Different CIDR Blocks

Modify the subnet CIDRs in `terraform.tfvars`:

```hcl
vpc_cidr             = "172.16.0.0/16"
public_subnet_cidrs  = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]
private_subnet_cidrs = ["172.16.11.0/24", "172.16.12.0/24", "172.16.13.0/24"]
```

### Different Region

Change the AWS region:

```hcl
aws_region = "us-west-2"
```

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

## Next Steps

After creating the VPC, you can:

1. Deploy EC2 instances in public/private subnets
2. Create RDS databases in private subnets
3. Set up EKS clusters using the subnets
4. Configure Application Load Balancers in public subnets
5. Add security groups and network ACLs

## Troubleshooting

### Module not found

If you get an error about the module source, ensure you're running Terraform from the `vpcmodule-usage` directory and the path to the module is correct.

### Provider version conflicts

Ensure the AWS provider version in `provider.tf` matches the version required by the module (>= 5.0).

## Additional Resources

- [VPC Module Documentation](../vpc-module/README.md)
- [Terraform Module Documentation](https://www.terraform.io/docs/language/modules/index.html)
- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)

