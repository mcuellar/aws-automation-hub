# --- EKS Cluster ---
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    # subnet_ids = aws_subnet.private[*].id
    subnet_ids = module.vpc.private_subnets  
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy
  ]
}

# --- Node Group ---
resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  # subnet_ids      = aws_subnet.private[*].id
  subnet_ids = module.vpc.private_subnets  
  instance_types  = [var.node_instance_type]
  scaling_config {
    desired_size = var.desired_capacity
    max_size     = 4
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy
  ]
}

# --- Data Sources ---
data "aws_eks_cluster" "cluster" {
  name = aws_eks_cluster.this.name
}

data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.this.name
}