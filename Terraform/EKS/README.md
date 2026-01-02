# EKS Cluster with VPC Terraform Configuration

This Terraform configuration creates a **production-grade** AWS EKS (Elastic Kubernetes Service) cluster with:
- A VPC with public and private subnets across **multiple availability zones** (similar to VPC-Only folder structure)
- **Multi-AZ EKS cluster** with high availability
- **Multi-AZ node group** automatically distributed across availability zones
- **IRSA (IAM Roles for Service Accounts)** configured with OIDC provider for secure pod-to-AWS authentication

## Key Production Features

✅ **Multi-AZ Deployment**: Cluster and nodes distributed across multiple availability zones for high availability  
✅ **IRSA OIDC**: Configured and ready for IAM Roles for Service Accounts  
✅ **Zero-Downtime Updates**: Configurable update strategy for node group  
✅ **Production Security**: Private subnets, security groups, and proper IAM roles

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- kubectl installed (for cluster interaction)
- Appropriate AWS IAM permissions

## Files Structure

- `provider.tf` - Terraform providers configuration
- `variables.tf` - Variable definitions
- `vpc.tf` - VPC, subnets, NAT gateways, route tables
- `iam.tf` - IAM roles for EKS cluster and node groups
- `eks.tf` - EKS cluster and node group configuration
- `outputs.tf` - Output values
- `terraform.tfvars.example` - Example variables file

## Quick Start

1. **Copy the example variables file:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit `terraform.tfvars` with your values:**
   - Update `aws_region` if needed
   - Update `project_name` and `environment`
   - Adjust VPC CIDR blocks if needed
   - Configure cluster name and node group settings
   - **Important:** Update `cluster_endpoint_public_access_cidrs` with your IP ranges for security

3. **Initialize Terraform:**
   ```bash
   terraform init
   ```

4. **Review the plan:**
   ```bash
   terraform plan
   ```

5. **Apply the configuration:**
   ```bash
   terraform apply
   ```

6. **Configure kubectl:**
   After the cluster is created, configure kubectl:
   ```bash
   aws eks update-kubeconfig --region <your-region> --name <cluster-name>
   ```

7. **Verify the cluster:**
   ```bash
   kubectl get nodes
   kubectl get pods --all-namespaces
   ```

## VPC Structure

The VPC configuration matches the structure in the VPC-Only folder:
- **VPC** with DNS support
- **Public Subnets** (3 subnets across availability zones)
- **Private Subnets** (3 subnets across availability zones)
- **Internet Gateway** for public subnets
- **NAT Gateways** (one per private subnet) for outbound internet access
- **Route Tables** for public and private subnets

## EKS Cluster Features

- **Multi-AZ Deployment**: 
  - Cluster control plane automatically distributed across multiple availability zones
  - Node group uses all private subnets across multiple AZs for high availability
  - Ensures resilience against single AZ failures
  
- **IRSA (IAM Roles for Service Accounts)**:
  - OIDC provider configured for secure pod-to-AWS-service authentication
  - Allows Kubernetes service accounts to assume IAM roles
  - No need to store AWS credentials in pods
  
- **Cluster**: EKS cluster with public and private API endpoints
- **Node Group**: Managed node group with auto-scaling capabilities across multiple AZs
- **Security Groups**: Separate security groups for cluster and nodes
- **IAM Roles**: Proper IAM roles for cluster and node groups
- **Zero-Downtime Updates**: Configurable update strategy for node group updates

## Node Group Configuration

The node group supports:
- **Multi-AZ Deployment**: Automatically distributes nodes across all private subnets (multiple availability zones)
- Auto-scaling (min, max, desired capacity)
- Multiple instance types for better distribution
- Configurable disk size
- ON_DEMAND or SPOT capacity types
- Deployed in private subnets for security
- Zero-downtime updates with configurable max unavailable percentage

## IRSA (IAM Roles for Service Accounts) Usage

IRSA is configured and ready to use. To create a service account with IAM role:

1. **Create an IAM Role** with trust policy allowing the OIDC provider:
```hcl
resource "aws_iam_role" "example_sa_role" {
  name = "example-service-account-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.cluster.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")}:sub" = "system:serviceaccount:default:example-sa"
          "${replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}
```

2. **Create a Kubernetes ServiceAccount**:
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: example-sa
  namespace: default
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/example-service-account-role
```

3. **Use the ServiceAccount in your Pod**:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example-pod
spec:
  serviceAccountName: example-sa
  containers:
  - name: app
    image: nginx
```

## Outputs

After deployment, you can access:
- VPC and subnet IDs
- Cluster endpoint and ARN
- Node group information
- kubectl configuration command

## Security Considerations

1. **Update `cluster_endpoint_public_access_cidrs`** in `terraform.tfvars` to restrict API access to your IP ranges
2. Nodes are deployed in private subnets for better security
3. Consider adding SSH key pair name in `eks.tf` if you need direct node access
4. Review security group rules and adjust as needed

## Cost Optimization

- Consider using SPOT instances for non-critical workloads (set `node_capacity_type = "SPOT"`)
- Adjust node counts based on your workload requirements
- Use appropriate instance types for your use case

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

## Troubleshooting

- **Cluster creation fails**: Check IAM permissions and ensure all required policies are attached
- **Nodes not joining**: Verify node group IAM role has all required policies
- **kubectl access denied**: Ensure your AWS credentials have EKS access permissions
- **Subnet issues**: Verify subnet CIDR blocks don't overlap and have enough IP addresses

