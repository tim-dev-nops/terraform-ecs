variable "environment" {
  description = "The Deployment environment"
}

variable "vpc_id" {
  description = "The VPC ID to use for the application load balancer"
}

variable "service_name" {
  description = "The name of the ECS service"
}

variable "service_listener_rule_priority" {
  description = "The priority for the listener rule"
  type        = number
}

variable "service_path_patterns" {
  description = "List of paths to foward to the service"
  type        = list(string)
}

variable "listern_id" {
  description = "ARN of listener to apply listener rule"
}

variable "cluster_id" {
  description = "ARN of ECS cluster to join"
}

variable "service_subnet_ids" {
  type        = list(any)
  description = "The subnet IDs to use for service networking"
}

variable "load_balancer_security_group_id" {
  description = "The security group id of the load balancer to allow ingress"
}
