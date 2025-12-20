# ═══════════════════════════════════════════════════════════════════════════
# Outputs for Jenkins Module
# ═══════════════════════════════════════════════════════════════════════════

output "jenkins_server_id" {
  description = "ID of the Jenkins EC2 instance"
  value       = aws_instance.jenkins_server.id
}

output "jenkins_public_ip" {
  description = "Public IP address of Jenkins server (Elastic IP)"
  value       = aws_eip.jenkins_eip.public_ip
}

output "jenkins_private_ip" {
  description = "Private IP address of Jenkins server"
  value       = aws_instance.jenkins_server.private_ip
}

output "jenkins_url" {
  description = "Jenkins web UI URL"
  value       = "http://${aws_eip.jenkins_eip.public_ip}:8080"
}

output "jenkins_ssh_command" {
  description = "SSH command to connect to Jenkins server"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ec2-user@${aws_eip.jenkins_eip.public_ip}"
}

output "jenkins_initial_password_command" {
  description = "Command to retrieve the initial Jenkins admin password"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ec2-user@${aws_eip.jenkins_eip.public_ip} 'sudo cat /var/lib/jenkins/secrets/initialAdminPassword'"
}

output "jenkins_security_group_id" {
  description = "ID of the Jenkins security group"
  value       = aws_security_group.jenkins_sg.id
}

output "jenkins_iam_role_arn" {
  description = "ARN of the Jenkins IAM role"
  value       = aws_iam_role.jenkins_role.arn
}

