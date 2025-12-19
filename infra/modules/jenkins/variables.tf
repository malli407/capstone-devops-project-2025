# ═══════════════════════════════════════════════════════════════════════════
# Jenkins Module Variables
# ═══════════════════════════════════════════════════════════════════════════

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where Jenkins will be deployed"
  type        = string
}

variable "public_subnet_id" {
  description = "ID of the public subnet for Jenkins server"
  type        = string
}

variable "key_name" {
  description = "Name of the EC2 key pair for SSH access"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for Jenkins server"
  type        = string
  default     = "t3.medium"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "jenkins_admin_password" {
  description = "Custom Jenkins admin password (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

