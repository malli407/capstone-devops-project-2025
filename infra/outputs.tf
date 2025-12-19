output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.vpc.private_subnet_ids
}

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS cluster"
  value       = module.eks.cluster_endpoint
  sensitive   = true
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "node_group_id" {
  description = "ID of the EKS node group"
  value       = module.eks.node_group_id
}

output "node_group_status" {
  description = "Status of the EKS node group"
  value       = module.eks.node_group_status
}

output "ecr_repo_urls" {
  description = "URLs of ECR repositories"
  value       = module.ecr.repository_urls
}

output "ecr_repo_arns" {
  description = "ARNs of ECR repositories"
  value       = module.ecr.repository_arns
}

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region}"
}

# ═══════════════════════════════════════════════════════════════════════════
# Jenkins Server Outputs
# ═══════════════════════════════════════════════════════════════════════════

output "jenkins_server_id" {
  description = "ID of the Jenkins EC2 instance"
  value       = module.jenkins.jenkins_server_id
}

output "jenkins_public_ip" {
  description = "Public IP address of Jenkins server"
  value       = module.jenkins.jenkins_public_ip
}

output "jenkins_url" {
  description = "Jenkins web UI URL (wait 5-10 minutes after apply for setup to complete)"
  value       = module.jenkins.jenkins_url
}

output "jenkins_ssh_command" {
  description = "SSH command to connect to Jenkins server"
  value       = module.jenkins.jenkins_ssh_command
}

output "jenkins_initial_password" {
  description = "Command to retrieve Jenkins initial admin password"
  value       = module.jenkins.initial_password_command
}

output "jenkins_info_command" {
  description = "Command to view complete Jenkins setup information"
  value       = module.jenkins.jenkins_info_command
}

