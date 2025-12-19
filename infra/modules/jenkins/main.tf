# ═══════════════════════════════════════════════════════════════════════════
# Jenkins Server Module - Automated Setup with All Tools Pre-installed
# ═══════════════════════════════════════════════════════════════════════════

# Data source for latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security Group for Jenkins Server
resource "aws_security_group" "jenkins_sg" {
  name        = "${var.project_name}-${var.environment}-jenkins-sg"
  description = "Security group for Jenkins server"
  vpc_id      = var.vpc_id

  # SSH access
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Jenkins UI access
  ingress {
    description = "Jenkins UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Vault UI access (optional)
  ingress {
    description = "Vault UI"
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound internet access
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-jenkins-sg"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# IAM Role for Jenkins Server
resource "aws_iam_role" "jenkins_role" {
  name = "${var.project_name}-${var.environment}-jenkins-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-jenkins-role"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# IAM Policy for Jenkins (ECR, EKS, S3, DynamoDB access)
resource "aws_iam_role_policy" "jenkins_policy" {
  name = "${var.project_name}-${var.environment}-jenkins-policy"
  role = aws_iam_role.jenkins_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:*",
          "eks:*",
          "ec2:*",
          "s3:*",
          "dynamodb:*",
          "iam:PassRole",
          "logs:*",
          "cloudwatch:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "${var.project_name}-${var.environment}-jenkins-profile"
  role = aws_iam_role.jenkins_role.name

  tags = {
    Name        = "${var.project_name}-${var.environment}-jenkins-profile"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Jenkins EC2 Instance
resource "aws_instance" "jenkins_server" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.jenkins_profile.name

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  user_data = templatefile("${path.module}/user-data.sh", {
    jenkins_admin_password = var.jenkins_admin_password
    region                = var.region
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-jenkins-server"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Purpose     = "CI/CD Server"
  }

  # Wait for instance to be fully ready
  provisioner "local-exec" {
    command = "echo 'Jenkins server provisioning started. This will take 5-10 minutes...'"
  }
}

# Elastic IP for Jenkins (Optional but recommended)
resource "aws_eip" "jenkins_eip" {
  instance = aws_instance.jenkins_server.id
  domain   = "vpc"

  tags = {
    Name        = "${var.project_name}-${var.environment}-jenkins-eip"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  depends_on = [aws_instance.jenkins_server]
}

