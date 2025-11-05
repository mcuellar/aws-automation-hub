variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "eks-workshop"
}

variable "cluster_version" {
  description = "EKS cluster version."
  type        = string
  default     = "1.33"
}

variable "ami_release_version" {
  description = "Default EKS AMI release version for node groups"
  type        = string
  default     = "1.33.0-20250704"
}

variable "vpc_cidr" {
  description = "Defines the CIDR block used on Amazon VPC created for Amazon EKS."
  type        = string
  default     = "10.42.0.0/20"
}

variable "remote_network_cidr" {
  description = "Defines the remote CIDR blocks used on Amazon VPC created for Amazon EKS Hybrid Nodes."
  type        = string
  default     = "10.52.0.0/20"
}

variable "remote_pod_cidr" {
  description = "Defines the remote CIDR blocks used on Amazon VPC created for Amazon EKS Hybrid Nodes."
  type        = string
  default     = "10.53.0.0/20"
}

variable "aws_region" {
  default = "us-east-1"
}

variable "node_instance_type" {
  description = "EC2 instance type for EKS nodes"
  type        = string
  default     = "t3.medium"
  validation {
    condition     = contains(["t3.small", "t3.medium"], var.node_instance_type)
    error_message = "node_instance_type must be either 't3.small' or 't3.medium'."
  }
}

variable "desired_capacity" {
  default = 2
}