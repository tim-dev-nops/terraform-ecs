locals {
  region = "us-east-2"
  environment = "production"
  production_availability_zones = ["us-east-2a", "us-east-2b"]
}

provider "aws" {
  region  = "${local.region}"
}

module "network" {
  source = "./modules/network"

  region               = local.region
  environment          = local.environment
  vpc_cidr             = "10.1.0.0/16"
  public_subnets_cidr  = ["10.1.2.0/24", "10.1.4.0/24"] 
  private_subnets_cidr = ["10.1.1.0/24", "10.1.3.0/24"]
  availability_zones   = local.production_availability_zones
}

module "cluster" {
  source = "./modules/cluster"

  ecs_cluster_name         = "dev-nops-demo"
  environment              = local.environment
  vpc_id                   = module.network.vpc_id
  load_balancer_subnet_ids = module.network.public_subnets_id
}

module "service" {
  source = "./modules/service"

  environment                     = local.environment
  vpc_id                          = module.network.vpc_id
  service_name                    = "dev-nops-demo-service"
  service_listener_rule_priority  = 100
  service_path_patterns           = ["/dev-nops-demo/*"]
  listern_id                      = module.cluster.cluster_alb_listener_id
  cluster_id                      = module.cluster.ecs_cluster_id
  service_subnet_ids              = module.network.private_subnets_id
  load_balancer_security_group_id = module.cluster.load_balancer_security_group_id
}
