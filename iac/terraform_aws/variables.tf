#############################
# AWS Account / Region
#############################

variable "project_id" {
  description = "Project name or environment tag"
  default     = "quangtp-mlops"
}

variable "aws_region" {
  description = "AWS region"
  default     = "eu-central-1"
}

variable "bucket" {
  description = "S3 bucket for MLOps"
  default     = "quangtp-mlops-bucket"
}

#############################
# EC2 Instance config
#############################

variable "instance_name" {
  description = "Name of EC2 instance"
  default     = "jenkins-k4"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t3.xlarge"
}

variable "ami_id" {
  description = "AMI ID for Ubuntu 22.04"
  default     = "ami-0a261c0e5f51090b1" # Example: Frankfurt, adjust if needed
}

variable "boot_disk_size" {
  description = "Root volume size (GB)"
  default     = 50
}

variable "firewall_name" {
  description = "Security group name"
  default     = "jenkins-firewall-k4"
}

#############################
# Networking
#############################

variable "vpc_id" {
  description = "VPC ID where resources are deployed"
  default = "vpc-0655d9ef3e7e3fc4f"
}

variable "subnet_id" {
  description = "Subnet ID for EC2 instance"
  default = "subnet-022bdd57cc15ffa53"
}

variable "subnet_ids" {
  description = "Subnet IDs for EKS cluster"
  type        = list(string)
  default = ["subnet-0e4e37350495d0fb1", "subnet-0122075429b8a391d"]
}

#############################
# SSH Key Pair
#############################

variable "key_pair_name" {
  description = "AWS EC2 Key Pair name (private key stored locally)"
  default = "my-iam-key"
}

#############################
# Optional: EKS Cluster
#############################

variable "eks_cluster_name" {
  description = "EKS cluster name"
  default     = "quangtp-eks"
}

variable "eks_node_group_name" {
  description = "EKS node group name"
  default     = "eks-node-group"
}

variable "eks_node_instance_type" {
  description = "EKS node EC2 instance type"
  default     = "t3.xlarge"
}

variable "eks_desired_capacity" {
  description = "Desired number of nodes"
  default     = 2
}

variable "eks_max_capacity" {
  description = "Maximum number of nodes"
  default     = 3
}

variable "eks_min_capacity" {
  description = "Minimum number of nodes"
  default     = 1
}