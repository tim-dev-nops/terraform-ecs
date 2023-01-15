# create a repository to store docker images
resource "aws_ecr_repository" "ecr" {
  name                 = var.service_name
  force_delete         = true
  image_tag_mutability = "IMMUTABLE"
}

# create the images/service_name on first run but ignore_changes to the value
# the allows the task to start with a default image
resource "aws_ssm_parameter" "service_image" {
  lifecycle {
    ignore_changes = [value]
  }
  name  = "/images/${var.service_name}"
  type  = "String"
  value = "nginxdemos/hello"
}

# read the latest image from SSM
# this will get the image 
data "aws_ssm_parameter" "service_image" {
  name = "/images/${var.service_name}"
  depends_on = [
    aws_ssm_parameter.service_image
  ]
}

# mark the image as nonsensitive
locals {
  service_image = nonsensitive(data.aws_ssm_parameter.service_image.value)
}

# the target group directs load balancer traffic to ECS tasks
resource "aws_lb_target_group" "service_target_group" {
  name        = "${var.service_name}-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  tags = {
    Environment = "${var.environment}"
  }
}

# The listener rule directs URLs with matching paths to
# the matching target group
resource "aws_lb_listener_rule" "service_listener_rule" {
  listener_arn = var.listern_id
  priority     = var.service_listener_rule_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service_target_group.arn
  }

  condition {
    path_pattern {
      values = var.service_path_patterns
    }
  }

  tags = {
    Environment = "${var.environment}"
  }
}

# ignore changes to container_definitions so an image change is ignored
# use the latest image from SSM so when other properties change the image is preserved
resource "aws_ecs_task_definition" "task_definition" {
  lifecycle {
    ignore_changes = [container_definitions]
  }
  family                   = "${var.service_name}-tdf"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  tags = {
    Environment = "${var.environment}"
  }
  container_definitions = <<TASK_DEFINITION
[
  {
    "name": "${var.service_name}-container",
    "image": "${local.service_image}",
    "essential": true,
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80,
        "protocol": "tcp"
      }
    ]
  }
]
TASK_DEFINITION
}

data "aws_ecs_task_definition" "task_definition" {
  task_definition = aws_ecs_task_definition.task_definition.family
}

resource "aws_security_group" "ecs_service_sg" {
  name        = "${var.service_name}-sg"
  description = "Security Group for the ECS Service"
  vpc_id      = var.vpc_id

  tags = {
    Environment = "${var.environment}"
  }
}

# Allow the load balancer to contact the ECS tasks on port 80
resource "aws_security_group_rule" "ecs_lb_ingress" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs_service_sg.id
  source_security_group_id = var.load_balancer_security_group_id
}

# Allow the ECS tasks to contact any host using any protocol
resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs_service_sg.id
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.service_name}-exec-role"
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_role" "ecs_task_role" {
  name               = "${var.service_name}-task-role"
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# use the aws_ecs_task_definition data source to get the max revision of the task definition
resource "aws_ecs_service" "service" {
  name                              = var.service_name
  cluster                           = var.cluster_id
  launch_type                       = "FARGATE"
  desired_count                     = 1
  health_check_grace_period_seconds = 30
  task_definition                   = "${aws_ecs_task_definition.task_definition.family}:${max(aws_ecs_task_definition.task_definition.revision, data.aws_ecs_task_definition.task_definition.revision)}"
  load_balancer {
    target_group_arn = aws_lb_target_group.service_target_group.arn
    container_name   = "${var.service_name}-container"
    container_port   = 80
  }
  network_configuration {
    subnets         = var.service_subnet_ids
    security_groups = [aws_security_group.ecs_service_sg.id]
  }
  tags = {
    Environment = "${var.environment}"
  }
}
