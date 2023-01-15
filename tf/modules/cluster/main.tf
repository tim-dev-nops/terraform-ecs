resource "aws_ecs_cluster" "cluster" {
  name = var.ecs_cluster_name

  tags = {
    Environment = "${var.environment}"
  }
}

resource "aws_security_group" "cluster_alb_sg" {
  name        = "${var.ecs_cluster_name}-alb-sg"
  description = "Security Group for the ALB"
  vpc_id      = var.vpc_id

  tags = {
    Environment = "${var.environment}"
  }
}

resource "aws_security_group_rule" "cluster_alb_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.cluster_alb_sg.id
}

resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.cluster_alb_sg.id
}

resource "aws_lb" "cluster_alb" {
  name               = "${var.ecs_cluster_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.cluster_alb_sg.id]
  subnets            = var.load_balancer_subnet_ids

  tags = {
    Environment = "${var.environment}"
  }
}

resource "aws_lb_listener" "cluster_alb_listener" {
  load_balancer_arn = aws_lb.cluster_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      status_code  = "404"
    }
  }

  tags = {
    Environment = "${var.environment}"
  }
}
