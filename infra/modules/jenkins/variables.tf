# ═══════════════════════════════════════════════════════════════════════════
# Variables for Jenkins Module
# ═══════════════════════════════════════════════════════════════════════════

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_id" {
  description = "ID of the public subnet for Jenkins server"
  type        = string
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
  default     = "capstone-key"
}

variable "instance_type" {
  description = "EC2 instance type for Jenkins server"
  type        = string
  default     = "t3.small"
}

variable "region" {
  description = "AWS region"
  type        = string
}

