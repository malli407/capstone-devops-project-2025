# ═══════════════════════════════════════════════════════════════════════════
# Jenkins Server Module
# Creates an EC2 instance with Jenkins and all required tools pre-installed
# ═══════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════════════
# Data Source: Get Latest Amazon Linux 2023 AMI
# ═══════════════════════════════════════════════════════════════════════════

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ═══════════════════════════════════════════════════════════════════════════
# Security Group for Jenkins Server
# ═══════════════════════════════════════════════════════════════════════════

resource "aws_security_group" "jenkins_sg" {
  name        = "${var.project_name}-jenkins-sg"
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

  # Jenkins web UI
  ingress {
    description = "Jenkins web UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-jenkins-sg"
  }
}

# ═══════════════════════════════════════════════════════════════════════════
# IAM Role for Jenkins Server
# ═══════════════════════════════════════════════════════════════════════════

resource "aws_iam_role" "jenkins_role" {
  name = "${var.project_name}-jenkins-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-jenkins-role"
  }
}

# Attach policies for EKS, ECR, S3, DynamoDB access
resource "aws_iam_role_policy_attachment" "jenkins_eks_full" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "jenkins_eks_worker" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "jenkins_ecr_full" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_role_policy_attachment" "jenkins_s3_full" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "jenkins_dynamodb_full" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

# Additional policy for EKS cluster access
resource "aws_iam_role_policy" "jenkins_eks_access" {
  name = "${var.project_name}-jenkins-eks-access"
  role = aws_iam_role.jenkins_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups",
          "eks:AccessKubernetesApi",
          "eks:ListUpdates",
          "eks:ListFargateProfiles"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "${var.project_name}-jenkins-profile"
  role = aws_iam_role.jenkins_role.name

  tags = {
    Name = "${var.project_name}-jenkins-profile"
  }
}

# ═══════════════════════════════════════════════════════════════════════════
# Elastic IP for Jenkins Server (Optional but recommended)
# ═══════════════════════════════════════════════════════════════════════════

resource "aws_eip" "jenkins_eip" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-jenkins-eip"
  }
}

resource "aws_eip_association" "jenkins_eip_assoc" {
  instance_id   = aws_instance.jenkins_server.id
  allocation_id = aws_eip.jenkins_eip.id
}

# ═══════════════════════════════════════════════════════════════════════════
# Jenkins EC2 Instance
# ═══════════════════════════════════════════════════════════════════════════

resource "aws_instance" "jenkins_server" {
  ami                    = data.aws_ami.amazon_linux_2023.id
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

  user_data = base64encode(templatefile("${path.module}/install-compact.sh", {
    region = var.region
  }))

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name = "${var.project_name}-jenkins-server"
  }

  lifecycle {
    create_before_destroy = false
  }
}

