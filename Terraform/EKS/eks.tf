# Security Group for EKS Cluster
resource "aws_security_group" "cluster" {
  name_prefix = "${var.project_name}-cluster-sg"
  vpc_id      = aws_vpc.main.id
  description = "Security group for EKS cluster control plane"

  tags = {
    Name = "${var.project_name}-cluster-sg"
  }
}

# Allow outbound traffic from cluster
resource "aws_security_group_rule" "cluster_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.cluster.id
  description       = "Allow all outbound traffic"
}

# Security Group for Worker Nodes
resource "aws_security_group" "nodes" {
  name_prefix = "${var.project_name}-nodes-sg"
  vpc_id      = aws_vpc.main.id
  description = "Security group for EKS worker nodes"

  tags = {
    Name = "${var.project_name}-nodes-sg"
  }
}

# Allow nodes to communicate with each other
resource "aws_security_group_rule" "nodes_internal" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
  security_group_id = aws_security_group.nodes.id
  description       = "Allow internal node communication"
}

# Allow all outbound traffic from nodes
resource "aws_security_group_rule" "nodes_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.nodes.id
  description       = "Allow all outbound traffic"
}

# Allow inbound from node security group
resource "aws_security_group_rule" "cluster_ingress_from_nodes" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.nodes.id
  security_group_id        = aws_security_group.cluster.id
  description              = "Allow inbound HTTPS from nodes"
}

# EKS Cluster - Multi-AZ Production Configuration
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  # Enable all control plane logging for production
  enabled_cluster_log_types = var.enabled_cluster_log_types

  # VPC Configuration - Uses all subnets across multiple AZs for high availability
  vpc_config {
    # Include both public and private subnets for multi-AZ deployment
    # EKS control plane will be distributed across AZs automatically
    subnet_ids              = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
    security_group_ids      = [aws_security_group.cluster.id]
    endpoint_private_access = true
    endpoint_public_access  = var.cluster_endpoint_public_access
    public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
  ]

  tags = {
    Name = var.cluster_name
  }
}

# EKS Node Group - Multi-AZ Production Configuration
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.node_group.arn
  # Use all private subnets to ensure multi-AZ deployment
  subnet_ids      = aws_subnet.private[*].id
  version         = var.kubernetes_version

  scaling_config {
    desired_size = var.desired_node_count
    max_size     = var.max_node_count
    min_size     = var.min_node_count
  }

  instance_types = var.node_instance_types
  capacity_type  = var.node_capacity_type

  disk_size = var.node_disk_size

  # Update configuration for zero-downtime updates
  update_config {
    max_unavailable_percentage = var.node_update_max_unavailable_percentage
  }

  # Remote access configuration (optional - only if key pair is provided)
  dynamic "remote_access" {
    for_each = var.node_key_pair_name != null ? [1] : []
    content {
      ec2_ssh_key = var.node_key_pair_name
    }
  }

  labels = {
    role = "general"
  }

  tags = {
    Name = "${var.cluster_name}-${var.node_group_name}"
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_policy,
    aws_iam_role_policy_attachment.node_cni_policy,
    aws_iam_role_policy_attachment.node_ecr_policy,
  ]
}

# Launch Template for Node Group (Production Best Practice)
# Note: For managed node groups, AWS handles the launch template automatically
# This is kept for reference but managed node groups don't require explicit launch templates
# The node group will automatically use EKS-optimized AMIs and proper configuration

# ==========================================
# IRSA (IAM Roles for Service Accounts) - OIDC Provider
# ==========================================
# IRSA allows Kubernetes service accounts to assume IAM roles
# This is the recommended way to grant AWS permissions to pods

# Get the OIDC issuer URL from the cluster
data "tls_certificate" "cluster" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# Create OIDC Provider for IRSA
resource "aws_iam_openid_connect_provider" "cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = {
    Name        = "${var.cluster_name}-irsa"
    Description = "OIDC Provider for IRSA (IAM Roles for Service Accounts)"
  }
}

# Example IAM Role for IRSA (commented out - use as template)
# Uncomment and customize for your service accounts
# resource "aws_iam_role" "example_service_account" {
#   name = "${var.cluster_name}-example-sa-role"
# 
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = {
#           Federated = aws_iam_openid_connect_provider.cluster.arn
#         }
#         Action = "sts:AssumeRoleWithWebIdentity"
#         Condition = {
#           StringEquals = {
#             "${replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")}:sub" = "system:serviceaccount:default:example-service-account"
#             "${replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")}:aud" = "sts.amazonaws.com"
#           }
#         }
#       }
#     ]
#   })
# 
#   tags = {
#     Name = "${var.cluster_name}-example-sa-role"
#   }
# }
#
# Then in Kubernetes, create a ServiceAccount:
# apiVersion: v1
# kind: ServiceAccount
# metadata:
#   name: example-service-account
#   namespace: default
#   annotations:
#     eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/CLUSTER_NAME-example-sa-role

