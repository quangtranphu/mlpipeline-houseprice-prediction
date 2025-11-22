provider "aws" {
  region = var.aws_region
}

#############################
# S3 Bucket
#############################
resource "aws_s3_bucket" "quangtp_bucket" {
  bucket        = var.bucket
  force_destroy = true
}

#############################
# IAM Role for EKS Cluster
#############################
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

#############################
# EKS Cluster
#############################
resource "aws_eks_cluster" "quangtp_eks" {
  name     = var.eks_cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = var.subnet_ids
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}

#############################
# IAM Role for Node Group
#############################
resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "ecr_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

#############################
# EKS Node Group
#############################
resource "aws_eks_node_group" "quangtp_nodes" {
  cluster_name    = aws_eks_cluster.quangtp_eks.name
  node_group_name = var.eks_node_group_name
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 4
  }

  instance_types = ["t3.medium"]
  disk_size      = 50
}

# ============================================================
# OIDC Provider (required for IRSA)
# ============================================================

data "tls_certificate" "oidc" {
  url = aws_eks_cluster.quangtp_eks.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "oidc" {
  url             = aws_eks_cluster.quangtp_eks.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]
}

# ============================================================
# IAM Role for EBS CSI Driver (IRSA)
# ============================================================

resource "aws_iam_role" "ebs_csi_role" {
  name = "AmazonEKS_EBS_CSI_DriverRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.oidc.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(aws_eks_cluster.quangtp_eks.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi_policy_attach" {
  role       = aws_iam_role.ebs_csi_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# ============================================================
# EBS CSI Addon
# ============================================================

resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = aws_eks_cluster.quangtp_eks.name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi_role.arn

  depends_on = [
    aws_iam_openid_connect_provider.oidc
  ]
}