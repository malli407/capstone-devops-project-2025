#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
# Jenkins Server Automated Installation Script
# This script runs on first boot to install and configure Jenkins + all tools
# ═══════════════════════════════════════════════════════════════════════════

set -e  # Exit on any error

# Logging
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "═══════════════════════════════════════════════════════════════════════════"
echo "Starting Jenkins Server Setup - $(date)"
echo "═══════════════════════════════════════════════════════════════════════════"

# ═══════════════════════════════════════════════════════════════════════════
# 1. SYSTEM UPDATE
# ═══════════════════════════════════════════════════════════════════════════
echo "[1/10] Updating system packages..."
yum update -y

# ═══════════════════════════════════════════════════════════════════════════
# 2. INSTALL JAVA (Required for Jenkins)
# ═══════════════════════════════════════════════════════════════════════════
echo "[2/10] Installing Java 11..."
amazon-linux-extras install java-openjdk11 -y
java -version

# ═══════════════════════════════════════════════════════════════════════════
# 3. INSTALL JENKINS
# ═══════════════════════════════════════════════════════════════════════════
echo "[3/10] Installing Jenkins..."
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
yum install jenkins -y

# Start Jenkins
systemctl start jenkins
systemctl enable jenkins

# Wait for Jenkins to start
echo "Waiting for Jenkins to start (this takes 1-2 minutes)..."
sleep 120

# ═══════════════════════════════════════════════════════════════════════════
# 4. INSTALL DOCKER
# ═══════════════════════════════════════════════════════════════════════════
echo "[4/10] Installing Docker..."
yum install docker -y
systemctl start docker
systemctl enable docker

# Add jenkins and ec2-user to docker group
usermod -aG docker jenkins
usermod -aG docker ec2-user

# ═══════════════════════════════════════════════════════════════════════════
# 5. INSTALL AWS CLI v2
# ═══════════════════════════════════════════════════════════════════════════
echo "[5/10] Installing AWS CLI v2..."
cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip
aws --version

# Configure AWS CLI to use instance role
mkdir -p /var/lib/jenkins/.aws
cat > /var/lib/jenkins/.aws/config << EOF
[default]
region = ${region}
output = json
EOF
chown -R jenkins:jenkins /var/lib/jenkins/.aws

# ═══════════════════════════════════════════════════════════════════════════
# 6. INSTALL KUBECTL
# ═══════════════════════════════════════════════════════════════════════════
echo "[6/10] Installing kubectl..."
cd /tmp
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/
kubectl version --client

# ═══════════════════════════════════════════════════════════════════════════
# 7. INSTALL TERRAFORM
# ═══════════════════════════════════════════════════════════════════════════
echo "[7/10] Installing Terraform..."
cd /tmp
wget https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip
unzip -q terraform_1.6.6_linux_amd64.zip
mv terraform /usr/local/bin/
rm terraform_1.6.6_linux_amd64.zip
terraform version

# ═══════════════════════════════════════════════════════════════════════════
# 8. INSTALL SAST TOOLS
# ═══════════════════════════════════════════════════════════════════════════
echo "[8/10] Installing SAST tools..."

# Trivy (Vulnerability Scanner)
echo "Installing Trivy..."
cd /tmp
wget https://github.com/aquasecurity/trivy/releases/download/v0.48.0/trivy_0.48.0_Linux-64bit.tar.gz
tar zxf trivy_0.48.0_Linux-64bit.tar.gz
mv trivy /usr/local/bin/
rm trivy_0.48.0_Linux-64bit.tar.gz
trivy --version

# kubeval (Kubernetes Manifest Validator)
echo "Installing kubeval..."
cd /tmp
wget https://github.com/instrumenta/kubeval/releases/latest/download/kubeval-linux-amd64.tar.gz
tar xf kubeval-linux-amd64.tar.gz
mv kubeval /usr/local/bin/
rm kubeval-linux-amd64.tar.gz
kubeval --version

# kube-linter (Kubernetes Best Practices)
echo "Installing kube-linter..."
cd /tmp
wget https://github.com/stackrox/kube-linter/releases/download/v0.6.5/kube-linter-linux.tar.gz
tar xf kube-linter-linux.tar.gz
mv kube-linter /usr/local/bin/
rm kube-linter-linux.tar.gz
kube-linter version

# ═══════════════════════════════════════════════════════════════════════════
# 9. INSTALL HASHICORP VAULT (Optional)
# ═══════════════════════════════════════════════════════════════════════════
echo "[9/10] Installing HashiCorp Vault..."
cd /tmp
wget https://releases.hashicorp.com/vault/1.15.4/vault_1.15.4_linux_amd64.zip
unzip -q vault_1.15.4_linux_amd64.zip
mv vault /usr/local/bin/
rm vault_1.15.4_linux_amd64.zip
vault version

# ═══════════════════════════════════════════════════════════════════════════
# 10. CONFIGURE JENKINS
# ═══════════════════════════════════════════════════════════════════════════
echo "[10/10] Configuring Jenkins..."

# Restart Jenkins to apply docker group changes
systemctl restart jenkins

# Wait for Jenkins to restart
sleep 60

# Get Jenkins initial admin password
JENKINS_PASSWORD=$(cat /var/lib/jenkins/secrets/initialAdminPassword)

# Save Jenkins info
cat > /home/ec2-user/jenkins-info.txt << EOF
═══════════════════════════════════════════════════════════════════════════
JENKINS SERVER READY!
═══════════════════════════════════════════════════════════════════════════

Jenkins URL: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080

Initial Admin Password: $JENKINS_PASSWORD

To login:
1. Access Jenkins URL in browser
2. Paste the Initial Admin Password above
3. Click "Install suggested plugins"
4. Create your admin user

Next Steps:
1. Configure Jenkins credentials (AWS keys)
2. Create pipeline job
3. Point to your Jenkinsfile in Git repo

Tool Versions Installed:
========================
Java:      $(java -version 2>&1 | head -n 1)
Jenkins:   $(jenkins --version 2>&1 || echo "Running")
Docker:    $(docker --version)
AWS CLI:   $(aws --version)
kubectl:   $(kubectl version --client --short 2>&1 | head -n 1)
Terraform: $(terraform version | head -n 1)
Trivy:     $(trivy --version | head -n 1)
kubeval:   $(kubeval --version)
kube-linter: $(kube-linter version)
Vault:     $(vault version)

Installation Log: /var/log/user-data.log

═══════════════════════════════════════════════════════════════════════════
EOF

chown ec2-user:ec2-user /home/ec2-user/jenkins-info.txt

# Display info in system log
cat /home/ec2-user/jenkins-info.txt

echo "═══════════════════════════════════════════════════════════════════════════"
echo "Jenkins Server Setup Complete! - $(date)"
echo "═══════════════════════════════════════════════════════════════════════════"

# Optional: Send notification (you can configure SNS here if needed)
# aws sns publish --topic-arn YOUR_SNS_TOPIC --message "Jenkins server is ready!"

