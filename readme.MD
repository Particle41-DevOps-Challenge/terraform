# AWS EKS Infrastructure with Terraform

This repository provisions a complete AWS infrastructure using Terraform.
It includes a VPC with public/private subnets, an EKS cluster, worker nodes, load balancer.

## 1. Architecture Overview

The Terraform configuration creates the following components:

## VPC

* 1 VPC
* 2 Public Subnets (for ALB)
* 2 Private Subnets (for EKS nodes & workloads)

## Networking

* Internet Gateway (IGW)
* NAT Gateway (NGW) for private subnet internet access
* Public & Private route tables

## EKS Cluster

* EKS control plane in private subnets

* Managed node group placed only in private subnets

* Node IAM roles & necessary policies

* Kubernetes add-ons (CNI, CoreDNS, Kube-proxy, Metrics-server, Pod Identity)

## Load Balancer

* Public-facing AWS Application Load Balancer (ALB)

* Deployed to public subnets

* SG rules allow ALB → nodes communication

## Container Deployment Workflow

* Build Docker image

* Tag the image

* Push to Amazon ECR

* Update Kubernetes Deployment (image version)

* ALB exposes your application publicly

## 2. Terraform Folder Structure

    ├── main.tf
    ├── variables.tf
    ├── data.tf
    ├── outputs.tf 
    ├── locals.tf
    └── README.md

## 3. Prerequisites

* Local Requirements

    * Terraform ≥ 1.5

    * AWS CLI ≥ 2.0

    * kubectl ≥ 1.27

    * Docker installed

* AWS Requirements

    IAM user or role with permissions for:
    * VPC
    * EC2
    * IAM
    * EKS
    * ELB
    * ECR

* Authenticate to AWS: aws configure

## 4. Terraform Setup Instructions

* Step 1: Initialize Terraform: terraform init

* Step 2: Validate configuration: terraform validate

* Step 3: Preview the infrastructure: terraform plan

* Step 4: Apply the infrastructure: terraform apply -auto-approve

## After Completion

    * VPC + subnets ready
    * EKS cluster created
    * Node group ready
    * ALB deployed

## 5. Connect to the EKS Cluster

* After Terraform apply finishes:

aws eks update-kubeconfig --name <cluster-name> --region us-east-1

* Then test:

    kubectl get nodes
    kubectl get pods -A

## 6. Deploy Your Application to EKS

* Step 1: Build Docker Image: docker build -t myapp .

* Step 2: Create ECR Repository: aws ecr create-repository --repository-name myapp

* Step 3: Authenticate Docker to ECR: 
    aws ecr get-login-password \
  --region us-east-1 | docker login \
  --username AWS \
  --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com

* Step 4: Tag Image
docker tag myapp:latest <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/myapp:latest

* Step 5: Push Image to ECR
docker push <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/myapp:latest


## 7. Security Group Rules (Summary)

* Security Group for EKS nodes

    ALB -> nodes (port 80)

    Node <-> node (TCP 0–65535)

    Outbound: allow all

* Security Group for ALB

    Inbound: HTTP (80) from Internet

    Outbound: to EKS nodes

## 8. Destroy Infrastructure

(Will delete all EKS resources, VPC, subnets, and ALB)

terraform destroy -auto-approve

## 9. Troubleshooting
* EKS Node Group taking too long

Normal. AWS takes 10–20 minutes to launch EC2 nodes & bootstrap.

## 10. Conclusion

This infrastructure provides:

* A production-grade AWS network layout

* Fully private EKS worker nodes

* Public ALB for external access
