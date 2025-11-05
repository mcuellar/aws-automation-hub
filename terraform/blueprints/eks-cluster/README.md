# EKS Cluster Blueprint

This blueprint provisions an Amazon EKS (Elastic Kubernetes Service) cluster using Terraform. It automates the creation of all necessary AWS resources for a production-ready Kubernetes environment.

## Features

- Creates an EKS cluster with configurable node groups
- Manages IAM roles and policies for EKS and worker nodes
- Sets up networking (VPC, subnets, security groups)
- Outputs cluster connection details

## Inputs

| Name                | Description                                 | Type     | Default      |
|---------------------|---------------------------------------------|----------|--------------|
| `cluster_name`      | Name of the EKS cluster                     | string   | `"eks-demo"` |
| `region`            | AWS region to deploy the cluster            | string   | `"us-west-2"`|
| `node_group_config` | Node group configuration (size, type, etc.) | object   | `{}`         |
| `vpc_id`            | VPC ID for the cluster                      | string   | `""`         |
| `subnet_ids`        | List of subnet IDs                          | list     | `[]`         |

## Outputs

| Name                  | Description                          |
|-----------------------|--------------------------------------|
| `cluster_id`          | EKS cluster ID                       |
| `cluster_endpoint`    | Kubernetes API server endpoint        |
| `cluster_ca_certificate` | Cluster CA certificate             |
| `node_group_role_arn` | IAM role ARN for node group          |

## Resources Created

- EKS Cluster
- Managed Node Groups
- IAM Roles and Policies
- VPC, Subnets, Security Groups (if not provided)
- Cluster Outputs

## Usage

1. **Clone the repository:**
    ```sh
    git clone https://github.com/your-org/aws-automation-hub.git
    cd aws-automation-hub/terraform/blueprints/eks-cluster
    ```

2. **Configure your variables:**
    Edit `terraform.tfvars` or pass variables via CLI.

3. **Initialize Terraform:**
    ```sh
    terraform init
    ```

4. **Plan and apply:**
    ```sh
    terraform plan
    terraform apply
    ```

5. **Access your cluster:**
    Use the output values to configure `kubectl`:
    ```sh
    aws eks --region <region> update-kubeconfig --name <cluster_name>
    ```

## Notes

- Ensure your AWS credentials are configured locally.
- Review IAM permissions before applying in production.
