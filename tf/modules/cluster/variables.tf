variable "environment" {
  description = "The Deployment environment"
}

variable "ecs_cluster_name" {
  description = "The name for the ECS Cluster"
}

variable "vpc_id" {
  description = "The VPC ID to use for the application load balancer"
}

variable "load_balancer_subnet_ids" {
  type        = list(any)
  description = "The subnet IDs to use for the application load balancer"
}
