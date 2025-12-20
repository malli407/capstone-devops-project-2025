#!/bin/bash
set -e
exec > /var/log/jenkins-setup.log 2>&1

AWS_REGION="${region}"

echo "=== Jenkins Setup Started: $(date) ==="

# Update system and install essential utilities first
yum update -y
yum install -y unzip wget curl git jq

# Install Java
yum install -y java-17-amazon-corretto-devel

# Install Jenkins (using curl for AL2023 compatibility)
curl -o /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
yum install -y jenkins
systemctl enable jenkins && systemctl start jenkins
sleep 30

# Install Docker
yum install -y docker
systemctl enable docker && systemctl start docker
usermod -aG docker jenkins
systemctl restart jenkins

# Install AWS CLI v2
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/aws.zip"
cd /tmp && unzip -q aws.zip && ./aws/install && rm -rf aws aws.zip
mkdir -p /var/lib/jenkins/.aws
echo -e "[default]\nregion = $AWS_REGION\noutput = json" > /var/lib/jenkins/.aws/config
chown -R jenkins:jenkins /var/lib/jenkins/.aws

# Install kubectl
curl -sLO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && mv kubectl /usr/local/bin/

# Install Terraform
curl -sLO https://releases.hashicorp.com/terraform/1.9.0/terraform_1.9.0_linux_amd64.zip
unzip -q terraform_1.9.0_linux_amd64.zip && mv terraform /usr/local/bin/ && rm terraform_1.9.0_linux_amd64.zip

# Install Trivy (using curl for AL2023 compatibility)
curl -sSfL https://github.com/aquasecurity/trivy/releases/download/v0.52.2/trivy_0.52.2_Linux-64bit.rpm -o /tmp/trivy.rpm
rpm -ivh /tmp/trivy.rpm
rm -f /tmp/trivy.rpm

# Install kubeval
curl -sLO https://github.com/instrumenta/kubeval/releases/download/v0.16.1/kubeval-linux-amd64.tar.gz
tar xf kubeval-linux-amd64.tar.gz && mv kubeval /usr/local/bin/ && rm kubeval-linux-amd64.tar.gz

# Install kube-linter
curl -sLO https://github.com/stackrox/kube-linter/releases/download/v0.6.8/kube-linter-linux.tar.gz
tar xf kube-linter-linux.tar.gz && mv kube-linter /usr/local/bin/ && rm kube-linter-linux.tar.gz

# Install Vault
curl -sLO https://releases.hashicorp.com/vault/1.15.4/vault_1.15.4_linux_amd64.zip
unzip -q vault_1.15.4_linux_amd64.zip && mv vault /usr/local/bin/ && rm vault_1.15.4_linux_amd64.zip

# Install Git & utilities (ensure wget is available for backward compatibility)
yum install -y git jq unzip wget curl

# Create info file
cat > /home/ec2-user/SETUP-INFO.txt << 'INFO'
=== JENKINS SERVER READY ===

URL: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080

Get password:
  sudo cat /var/lib/jenkins/secrets/initialAdminPassword

Tools installed:
  ✓ Java 17, Jenkins, Docker
  ✓ AWS CLI, kubectl, Terraform
  ✓ Trivy, kubeval, kube-linter
  ✓ Vault CLI, Git

Logs: /var/log/jenkins-setup.log
INFO
chown ec2-user:ec2-user /home/ec2-user/SETUP-INFO.txt

echo "=== Jenkins Setup Completed: $(date) ==="
