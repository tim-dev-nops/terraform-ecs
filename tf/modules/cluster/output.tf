output "ecs_cluster_id" {
  value = aws_ecs_cluster.cluster.id
}

output "load_balancer_security_group_id" {
  value = aws_security_group.cluster_alb_sg.id
}

output "load_balancer_id" {
  value = aws_lb.cluster_alb.id
}

output "load_balancer_dns" {
  value = aws_lb.cluster_alb.dns_name
}

output "cluster_alb_listener_id" {
  value = aws_lb_listener.cluster_alb_listener.id
}
