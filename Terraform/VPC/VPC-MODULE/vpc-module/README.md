# VPC Terraform Module

A reusable Terraform module for creating a production-ready AWS VPC infrastructure with high availability and cost optimization measures.

## Features

- **Multi-AZ Deployment**: Public and private subnets across multiple availability zones
- **NAT Gateways**: One NAT gateway per availability zone for private subnet internet access
- **Internet Gateway**: Single IGW for public internet connectivity
- **Route Tables**: Separate route tables for public and private subnets
- **High Availability**: Fault-tolerant architecture across multiple AZs
- **Cost Optimized**: Efficient NAT gateway placement and resource tagging

## Architecture

The module creates:
- 1 VPC with DNS support enabled
- 1 Internet Gateway
- 3 Public Subnets (one per AZ)
- 3 Private Subnets (one per AZ)
- 3 NAT Gateways with Elastic IPs (one per AZ)
- 1 Public Route Table
- 3 Private Route Tables (one per AZ)

## Usage

### Basic Example

```hcl
module "vpc" {
  source = "../vpc-module"

  project_name = "my-project"
  environment  = "production"
  aws_region   = "us-east-1"
  
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}
```

### Complete Example with Provider

```hcl
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  
  default_tags {
    tags = {
      Project     = "my-project"
      Environment = "production"
      ManagedBy   = "Terraform"
    }
  }
}

module "vpc" {
  source = "../vpc-module"

  project_name = "my-project"
  environment  = "production"
  aws_region   = "us-east-1"
  
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

# Use module outputs
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}
```

## How to Run the Module

### Prerequisites

1. **AWS Account**: Ensure you have an AWS account with appropriate permissions
2. **AWS CLI**: Configure AWS credentials (optional, but recommended)
   ```bash
   aws configure
   ```
3. **Terraform**: Install Terraform >= 1.0
   - Download from [terraform.io](https://www.terraform.io/downloads)
   - Verify installation: `terraform version`

### Step-by-Step Instructions

#### Option 1: Using the Example Usage Directory (Recommended)

1. **Navigate to the example usage directory:**
   ```bash
   cd Terraform/MODULE/vpcmodule-usage
   ```

2. **Copy the example variables file:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. **Edit `terraform.tfvars` with your values:**
   ```hcl
   aws_region   = "us-east-1"
   project_name = "my-company"
   environment  = "production"
   
   vpc_cidr             = "10.0.0.0/16"
   public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
   private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
   ```

4. **Initialize Terraform:**
   ```bash
   terraform init
   ```
   This will:
   - Download the AWS provider
   - Initialize the VPC module from `../vpc-module`

5. **Review the execution plan:**
   ```bash
   terraform plan
   ```
   Review the plan to see what resources will be created.

6. **Apply the configuration:**
   ```bash
   terraform apply
   ```
   Type `yes` when prompted to confirm.

7. **View outputs:**
   ```bash
   terraform output
   ```
   This will display all module outputs including VPC ID, subnet IDs, NAT gateway IPs, etc.

#### Option 2: Using the Module in Your Own Terraform Configuration

1. **Create your Terraform configuration files** (e.g., `main.tf`, `provider.tf`, `variables.tf`)

2. **Add the module block** in your `main.tf`:
   ```hcl
   module "vpc" {
     source = "../MODULE/vpc-module"
     
     project_name = var.project_name
     environment  = var.environment
     aws_region   = var.aws_region
     
     vpc_cidr             = var.vpc_cidr
     public_subnet_cidrs  = var.public_subnet_cidrs
     private_subnet_cidrs = var.private_subnet_cidrs
   }
   ```

3. **Configure the provider** in `provider.tf`:
   ```hcl
   terraform {
     required_version = ">= 1.0"
     
     required_providers {
       aws = {
         source  = "hashicorp/aws"
         version = "~> 5.0"
       }
     }
   }
   
   provider "aws" {
     region = var.aws_region
     
     default_tags {
       tags = {
         Project     = var.project_name
         Environment = var.environment
         ManagedBy   = "Terraform"
       }
     }
   }
   ```

4. **Define variables** in `variables.tf` (or use defaults)

5. **Initialize and apply:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

### Accessing Module Outputs

After the module is applied, you can access outputs in your configuration:

```hcl
# Use VPC ID in other resources
resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "Security group for web servers"
  vpc_id      = module.vpc.vpc_id
  
  # ... other configuration
}

# Use subnet IDs
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  subnet_id     = module.vpc.public_subnet_ids[0]
  
  tags = {
    Name = "web-server"
  }
}
```

### Destroying Resources

To destroy all resources created by the module:

```bash
terraform destroy
```

Type `yes` when prompted to confirm. This will remove:
- VPC and all subnets
- Internet Gateway
- NAT Gateways and Elastic IPs
- Route Tables

**Note:** Ensure no other resources depend on the VPC before destroying.

### Troubleshooting

#### Module Not Found Error
```
Error: Module not found
```
**Solution:** Ensure you're running `terraform init` from the correct directory and the module path is correct.

#### Provider Authentication Error
```
Error: error configuring Terraform AWS Provider: no valid credential sources found
```
**Solution:** Configure AWS credentials using:
- `aws configure` command, or
- Environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`), or
- AWS credentials file (`~/.aws/credentials`)

#### Insufficient Permissions
```
Error: AccessDenied
```
**Solution:** Ensure your AWS IAM user/role has permissions for:
- VPC creation and management
- EC2 (for subnets, gateways, route tables)
- Elastic IP allocation

### Next Steps

After successfully deploying the VPC module:

1. **Deploy EC2 instances** in public/private subnets
2. **Create RDS databases** in private subnets
3. **Set up EKS clusters** using the subnets
4. **Configure Application Load Balancers** in public subnets
5. **Add security groups** and network ACLs for additional security

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aws_region | AWS region for deployment | `string` | `"us-east-1"` | no |
| project_name | Project name for resource naming | `string` | `"my-project"` | no |
| environment | Environment name | `string` | `"production"` | no |
| vpc_cidr | CIDR block for VPC | `string` | `"10.0.0.0/16"` | no |
| public_subnet_cidrs | CIDR blocks for public subnets | `list(string)` | `["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]` | no |
| private_subnet_cidrs | CIDR blocks for private subnets | `list(string)` | `["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | VPC ID |
| vpc_cidr | VPC CIDR block |
| public_subnet_ids | List of public subnet IDs |
| public_subnet_cidrs | List of public subnet CIDR blocks |
| private_subnet_ids | List of private subnet IDs |
| private_subnet_cidrs | List of private subnet CIDR blocks |
| nat_gateway_ids | List of NAT Gateway IDs |
| nat_gateway_ips | List of NAT Gateway public IPs (Elastic IPs) |
| internet_gateway_id | Internet Gateway ID |
| public_route_table_id | Public Route Table ID |
| private_route_table_ids | List of Private Route Table IDs |

## Examples

See the `../vpcmodule-usage` directory for complete working examples.

## Notes

- The module automatically selects available AZs using `data.aws_availability_zones`
- All resources are tagged with Project, Environment, and ManagedBy tags (via provider default_tags)
- NAT gateways are placed in public subnets, one per availability zone
- Private subnets route outbound traffic through their respective NAT gateways

## Cost Estimation

Approximate monthly costs:
- VPC: Free
- Subnets: Free
- Internet Gateway: Free
- Elastic IPs (attached): Free
- NAT Gateways (3x): ~$97/month
- Data Processing: ~$0.05/GB

**Total: ~$97/month** (excluding data transfer costs)

## License

Internal use only
