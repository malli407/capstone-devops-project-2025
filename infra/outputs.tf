output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "ecr_repo_urls" {
  value = module.ecr.repository_urls
}

# ═══════════════════════════════════════════════════════════════════════════
# Jenkins Server Outputs
# ═══════════════════════════════════════════════════════════════════════════

output "jenkins_url" {
  description = "Jenkins web UI URL"
  value       = module.jenkins.jenkins_url
}

output "jenkins_public_ip" {
  description = "Jenkins server public IP (Elastic IP)"
  value       = module.jenkins.jenkins_public_ip
}

output "jenkins_ssh_command" {
  description = "SSH command to connect to Jenkins server"
  value       = module.jenkins.jenkins_ssh_command
}

output "jenkins_initial_password_command" {
  description = "Command to retrieve initial Jenkins admin password"
  value       = module.jenkins.jenkins_initial_password_command
}
