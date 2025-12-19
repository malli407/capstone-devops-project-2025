# capstone-devops-project-2025
Devops Academy capstone project code 


# 🚀 AWS EKS DevOps Capstone Project

## 👤 **Authors**
Kanaparthi Reddy, Poruru Anudeep and Ansari

**GL-Capstone-Project-PAN-2025**  
GlobalLogic Batch 1 - 2025 - capstone project

## ✅ **Requirements Met**

### **1. AWS Infrastructure Setup (Terraform)**
✅ VPC with 2 public and 2 private subnets across multiple AZs  
✅ Internet Gateway, NAT Gateway, Route Tables  
✅ Security Groups for HTTP (80), SSH (22), Jenkins (8080), Vault (8200)  
✅ Fully automated with Terraform modules

### **2. EKS Cluster Setup**
✅ EKS cluster with managed node groups  
✅ 2 worker nodes (t3.medium)  
✅ Kubernetes version 1.28  
✅ Auto-scaling configuration (min: 1, max: 4)

### **3. ECR Repository**
✅ Private ECR repository for Docker images  
✅ Image scanning on push  
✅ Lifecycle policies for image management

### **4. Kubernetes Manifests**
✅ Namespace, ConfigMap, Secret (with secure management)  
✅ Deployment with 2 replicas  
✅ StorageClass (AWS EBS gp3)  
✅ PersistentVolumeClaim (5GB content + 2GB logs)  
✅ Resource limits and health checks

### **5. Classic Load Balancer**
✅ AWS Classic ELB integration  
✅ Automatic provisioning via Kubernetes Service  
✅ Health checks and traffic routing

### **6. Jenkins Automation + Security**
✅ **Jenkins Server:** Automated EC2 setup with all tools pre-installed  
✅ **CI/CD Pipeline:** Complete Jenkinsfile for infrastructure and app deployment  
✅ **SAST Tools:** Trivy, kubeval, kube-linter  
✅ **DAST Tool:** OWASP ZAP baseline scanning  
✅ **Secret Management:** HashiCorp Vault integration


                        DEPLOYMENT FLOW
                        
  Developer → Git Push → Jenkins Pipeline → Build Docker Image
       ↓
  Push to ECR → Deploy to EKS → Create Pods → Expose via Load Balancer
       ↓
  SAST Scan (Trivy) → DAST Scan (OWASP ZAP) → Application Running ✅
```

**Key Components:**
- **Jenkins Server (Public Subnet):** CI/CD automation hub
- **EKS Worker Nodes (Private Subnets):** Run application pods
- **Classic Load Balancer (Public):** Routes traffic to pods
- **ECR (Managed Service):** Stores Docker images
- **S3 + DynamoDB:** Terraform state management

---


## 🚀 **Quick Start**

### **Step 1: Clone Repository**
```bash
git clone <repo-url>
cd AWS-EKS-DevOps-Capstone-Project
```

### **Step 2: Create EC2 Key Pair**
```bash
aws ec2 create-key-pair \
  --key-name capstone-key \
  --region ap-south-1 \
  --query 'KeyMaterial' \
  --output text > ~/.ssh/capstone-key.pem

chmod 400 ~/.ssh/capstone-key.pem
```

### **Step 3: Update Variables (Optional)**
Edit `infra/variables.tf` if you want to customize:
- AWS region (default: `ap-south-1`)
- EC2 key pair name (default: `capstone-key`)
- Instance types, node counts, etc.

### **Step 4: Deploy Infrastructure**
```bash
cd infra/

# Initialize Terraform
terraform init

# Review plan
terraform plan

# Deploy (takes 20-25 minutes)
terraform apply -auto-approve
```

### **Step 5: Get Jenkins Access**
```bash
# Get Jenkins URL
terraform output jenkins_url

# Get initial admin password
terraform output -raw jenkins_initial_password | bash

# Example output:
# Jenkins URL: http://13.234.56.78:8080
# Password: a1b2c3d4e5f6...
```

### **Step 6: Login to Jenkins**
1. Open Jenkins URL in browser
2. Enter initial admin password
3. Install suggested plugins
4. Create admin user
5. Start using Jenkins!

### **Step 7: Create Jenkins Pipeline Job**
1. Click **"New Item"**
2. Name: `Capstone-Project-Pipeline`
3. Type: **Pipeline**
4. **Pipeline Definition:** Pipeline script from SCM
5. **SCM:** Git
6. **Repository URL:** Your Git repo URL
7. **Script Path:** `Jenkinsfile`
8. Add parameters:
   - `ACTION` (Choice: apply, destroy)
   - `SKIP_TESTS` (Boolean: false)
9. **Save**

### **Step 8: Run Pipeline**
1. Click **"Build with Parameters"**
2. Select `ACTION = apply`
3. Click **"Build"**
4. Wait 30-40 minutes for complete deployment

### **Step 9: Access Your Application**
```bash
# Get Load Balancer URL
kubectl get svc nginx-service -n app

# Example output:
# NAME            TYPE           EXTERNAL-IP
# nginx-service   LoadBalancer   a1b2c3...elb.amazonaws.com

# Open in browser:
# http://a1b2c3...elb.amazonaws.com
```

**🎉 Your Calculator App is Running!**

---

## 🧮 **Application Details**

### **Calculator Web Application**

**Type:** Interactive Web Calculator  
**Technology:** HTML5, CSS3, JavaScript  
**Features:**
- Basic arithmetic operations (+, -, ×, ÷, %)
- Responsive design (mobile-friendly)
- Calculation history display
- Error handling (division by zero, etc.)
- Keyboard support
- Modern gradient UI (blue to purple theme)
- GlobalLogic branding

**Demo:**
```
┌─────────────────────────────────────┐
│  GL-Capstone-Project-PAN-2025       │
│  GL GlobalLogic Calculator          │
│                                     │
│  ┌───────────────────────────────┐  │
│  │              0                │  │  ← Display
│  └───────────────────────────────┘  │
│                                     │
│  ┌───┬───┬───┬───┐                 │
│  │ C │ ⌫ │ % │ ÷ │                 │
│  ├───┼───┼───┼───┤                 │
│  │ 7 │ 8 │ 9 │ × │                 │
│  ├───┼───┼───┼───┤                 │
│  │ 4 │ 5 │ 6 │ - │                 │
│  ├───┼───┼───┼───┤                 │
│  │ 1 │ 2 │ 3 │ + │                 │
│  ├───┼───┼───────┤                 │
│  │ 0 │ . │   =   │                 │
│  └───┴───┴───────┘                 │
└─────────────────────────────────────┘
```

**Access:** `http://<LOAD_BALANCER_URL>`

## 🐛 **Troubleshooting**

### **Common Issues & Solutions**

#### **1. Terraform Apply Fails**
```bash
# Check AWS credentials
aws sts get-caller-identity

# Verify AWS region
aws configure get region

# Check Terraform version
terraform version  # Should be >= 1.5.0

# Re-initialize if needed
terraform init -reconfigure
```

#### **2. Jenkins Not Accessible**
```bash
# Check Jenkins EC2 instance status
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=capstone-project-dev-jenkins" \
  --query 'Reservations[].Instances[].State.Name'

# Check security group rules
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=*jenkins*" \
  --query 'SecurityGroups[].IpPermissions'

# SSH to Jenkins server and check logs
ssh -i ~/.ssh/capstone-key.pem ec2-user@<JENKINS_IP>
sudo systemctl status jenkins
sudo journalctl -u jenkins -f
```

#### **3. EKS Cluster Connection Issues**
```bash
# Update kubeconfig
aws eks update-kubeconfig \
  --name capstone-project-eks-cluster \
  --region ap-south-1

# Test connection
kubectl get nodes
kubectl cluster-info

# Check IAM permissions
aws eks describe-cluster \
  --name capstone-project-eks-cluster \
  --region ap-south-1
```

#### **4. Pods Not Starting**
```bash
# Check pod status
kubectl get pods -n app

# Describe pod for details
kubectl describe pod <POD_NAME> -n app

# Check pod logs
kubectl logs <POD_NAME> -n app

# Check events
kubectl get events -n app --sort-by='.lastTimestamp'
```

#### **5. Load Balancer Not Working**
```bash
# Check service status
kubectl get svc nginx-service -n app

# Wait for EXTERNAL-IP (takes 2-3 minutes)
kubectl get svc nginx-service -n app -w

# Check AWS ELB
aws elb describe-load-balancers \
  --query 'LoadBalancerDescriptions[].DNSName'

# Test health checks
curl -I http://<LOAD_BALANCER_URL>
```

### **Getting Help**
- Check logs: `kubectl logs <pod-name> -n app`
- Describe resources: `kubectl describe <resource> <name> -n app`
- Review documentation: `docs/`
- Check Jenkins console output for pipeline errors

---

## 📞 **Support & Contact**

### **Documentation**
- All guides available in `docs/` folder
- Start with `docs/START-HERE.md`

### **Issues**
- Found a bug? Open an issue on GitHub
- Need help? Check `docs/MANUAL-DEPLOYMENT-GUIDE.md`

---

## 👤 **Author**

**GL-Capstone-Project-PAN-2025**  
GlobalLogic Batch 1 - 2025
