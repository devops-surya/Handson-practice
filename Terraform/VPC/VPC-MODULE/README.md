# Terraform Modules

This directory contains reusable Terraform modules for AWS infrastructure.

## Available Modules

### VPC Module (`vpc-module/`)

A production-ready VPC module that creates:
- Multi-AZ VPC with public and private subnets
- Internet Gateway for public access
- NAT Gateways (one per AZ) for private subnet internet access
- Route tables for proper traffic routing

**Location:** `vpc-module/`

**Documentation:** [VPC Module README](vpc-module/README.md)

**Example Usage:** [VPC Module Usage](vpcmodule-usage/)

## Module Structure

```
MODULE/
├── vpc-module/          # VPC Terraform module
│   ├── vpc.tf          # VPC resources
│   ├── variables.tf    # Module inputs
│   ├── outputs.tf      # Module outputs
│   ├── versions.tf     # Terraform and provider requirements
│   └── README.md       # Module documentation
│
└── vpcmodule-usage/     # Example showing how to use the VPC module
    ├── provider.tf     # Terraform and AWS provider configuration
    ├── main.tf         # Module usage example
    ├── variables.tf    # Input variables
    ├── outputs.tf      # Output values
    ├── terraform.tfvars.example  # Example variable values
    └── README.md       # Usage instructions
```

## How to Use a Module

### 1. Basic Usage

```hcl
module "vpc" {
  source = "./MODULE/vpc-module"

  project_name = "my-project"
  environment  = "production"
  aws_region   = "us-east-1"
  
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}
```

### 2. Using Module Outputs

```hcl
# Access module outputs
output "vpc_id" {
  value = module.vpc.vpc_id
}

# Use outputs in other resources
resource "aws_instance" "web" {
  subnet_id = module.vpc.public_subnet_ids[0]
  # ... other configuration
}
```

### 3. Complete Example

See the `vpcmodule-usage/` directory for a complete working example.

## Module Development Guidelines

When creating new modules:

1. **No Provider Configuration**: Modules should not contain `provider` blocks. Providers are configured in the root module.

2. **Version Requirements**: Include `versions.tf` with Terraform and provider version requirements.

3. **Documentation**: Each module should have a comprehensive README.md with:
   - Description and features
   - Usage examples
   - Input variables table
   - Outputs table
   - Requirements

4. **Variables**: Use descriptive variable names with defaults where appropriate.

5. **Outputs**: Expose all important resource IDs and attributes as outputs.

6. **Tags**: Use provider-level default tags rather than module-level tags.

## Best Practices

- **Reusability**: Design modules to be reusable across different projects
- **Flexibility**: Provide variables for customization
- **Documentation**: Keep documentation up to date
- **Testing**: Test modules in isolation before using in production
- **Versioning**: Consider versioning modules for production use

## Examples

### Using VPC Module in EKS Setup

```hcl
# Use VPC module
module "vpc" {
  source = "../MODULE/vpc-module"
  # ... configuration
}

# Use VPC outputs in EKS
module "eks" {
  source = "../EKS"
  
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
}
```

## Contributing

When adding new modules:

1. Create a new directory under `MODULE/`
2. Follow the module structure guidelines
3. Include comprehensive documentation
4. Add an example usage in `vpcmodule-usage/` or create a new example directory
5. Update this README with the new module information

## License

Internal use only

