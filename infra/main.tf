module "vpc" {
  source                = "./modules/vpc"
  project_name          = var.project_name
  vpc_cidr              = var.vpc_cidr
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  azs                   = var.azs
  ssh_cidr              = var.ssh_cidr
}

module "eks" {
  source               = "./modules/eks"
  project_name         = var.project_name
  cluster_name         = var.cluster_name
  eks_version          = var.eks_version
  private_subnet_ids   = module.vpc.private_subnet_ids
  vpc_id               = module.vpc.vpc_id
  vpc_cidr             = var.vpc_cidr
  node_instance_type   = var.node_instance_type
  node_disk_size       = var.node_disk_size
  node_desired         = var.node_desired
  node_min             = var.node_min
  node_max             = var.node_max
}

module "ecr" {
  source       = "./modules/ecr"
  repositories = var.ecr_repositories
}

# ═══════════════════════════════════════════════════════════════════════════
# Jenkins Server Module (CI/CD Automation)
# ═══════════════════════════════════════════════════════════════════════════

module "jenkins" {
  source = "./modules/jenkins"
  
  project_name     = var.project_name
  vpc_id           = module.vpc.vpc_id
  public_subnet_id = module.vpc.public_subnet_ids[0]  # Deploy in first public subnet
  key_name         = var.key_name
  instance_type    = var.jenkins_instance_type
  region           = var.region
  
  depends_on = [module.vpc]
}
