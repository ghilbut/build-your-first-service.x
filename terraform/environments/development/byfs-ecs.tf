locals {
  az_suffixes = ["a", "b", "c"]
  api_domains = {
    development = "byfs-dev.api.${var.root_domain}"
  }
}

locals {
  api_domain = local.api_domains[terraform.workspace]

}

data aws_vpc default {
  default = true
}

data aws_subnet defaults {
  count = length(local.az_suffixes)

  availability_zone = "${var.aws_region}${local.az_suffixes[count.index]}"
  default_for_az = true
}

resource aws_security_group django {
  name        = "byfs-django"
  description = "Allow all traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = -1
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource aws_lb django {
  name               = "alb-byfs"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.django.id]
  subnets            = data.aws_subnet.defaults.*.id
}

resource aws_lb_target_group django {
  name     = "alb-byfs-django"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
  target_type = "ip"

  #health_check {
  #  enabled = false
  #}
}

resource aws_lb_listener django {
  load_balancer_arn = aws_lb.django.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.django.arn
  }
}

resource aws_lb_listener_rule django {
  listener_arn = aws_lb_listener.django.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.django.arn
  }

  condition {
    host_header {
      values = [local.api_domain]
    }
  }

  condition {
    path_pattern {
      values = [
        "/v*",
        "/admin",
      ]
    }
  }
}

resource aws_route53_record django {
  zone_id = data.aws_route53_zone.public.zone_id
  name    = local.api_domain
  type    = "A"

  alias {
    name    = aws_lb.django.dns_name
    zone_id = aws_lb.django.zone_id
    evaluate_target_health = true
  }
}





resource aws_ecs_cluster byfs {
  name               = "ecs-byfs"
  capacity_providers = [
    "FARGATE",
    "FARGATE_SPOT",
  ]

  setting {
    name  = "containerInsights"
    #value = "enabled"
    value = "disabled"
  }

  #tags = var.tags
}

#resource aws_appautoscaling_target app_scale_target {
#  service_namespace  = "ecs"
#  resource_id        = "service/${aws_ecs_cluster.byfs.name}/${aws_ecs_service.django.name}"
#  scalable_dimension = "ecs:service:DesiredCount"
#  max_capacity       = 8
#  min_capacity       = 1
#}

resource aws_ecs_task_definition django {
  family                   = "ecs-byfs-${terraform.workspace}-task-definition"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn

  # defined in role.tf
  #task_role_arn = aws_iam_role.app_role.arn

  container_definitions = <<DEFINITION
[
  {
    "name": "django",
    "image": "nginx:latest",
    "essential": true,
    "portMappings": [
      {
        "protocol": "tcp",
        "containerPort": 80
      }
    ]
  }
]
DEFINITION


  #tags = var.tags
}

resource aws_ecs_service django {
  depends_on = [aws_lb_listener.django]

  lifecycle {
    ignore_changes = [task_definition]
  }

  name            = "ecs-byfs-${terraform.workspace}-service"
  cluster         = aws_ecs_cluster.byfs.id
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.django.arn
  desired_count   = 1

  network_configuration {
    subnets          = data.aws_subnet.defaults.*.id
    security_groups  = [aws_security_group.django.id]

    # if you has NAT, disable
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.django.id
    container_name   = "django"
    container_port   = 80
  }

  deployment_controller {
    type = "ECS"
  }
}

# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html
resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "iam-role-byfs-ecs-execution"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
