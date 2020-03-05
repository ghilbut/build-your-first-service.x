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
  port     = 8000
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





resource aws_secretsmanager_secret mysql_host {
  name = "byfs-${terraform.workspace}-mysql-host"
}

resource aws_secretsmanager_secret_version mysql_host {
  secret_id     = aws_secretsmanager_secret.mysql_host.id
  secret_string = var.mysql_address
}

resource aws_secretsmanager_secret mysql_name {
  name = "byfs-${terraform.workspace}-mysql-name"
}

resource aws_secretsmanager_secret_version mysql_name {
  secret_id     = aws_secretsmanager_secret.mysql_name.id
  secret_string = "development"
}

resource aws_secretsmanager_secret mysql_port {
  name = "byfs-${terraform.workspace}-mysql-port"
}

resource aws_secretsmanager_secret_version mysql_port {
  secret_id     = aws_secretsmanager_secret.mysql_port.id
  secret_string = "3306"
}

resource aws_secretsmanager_secret mysql_username {
  name = "byfs-${terraform.workspace}-mysql-username"
}

resource aws_secretsmanager_secret_version mysql_username {
  secret_id     = aws_secretsmanager_secret.mysql_username.id
  secret_string = var.mysql_username
}

resource aws_secretsmanager_secret mysql_password {
  name = "byfs-${terraform.workspace}-mysql-password"
}

resource aws_secretsmanager_secret_version mysql_password {
  secret_id     = aws_secretsmanager_secret.mysql_password.id
  secret_string = var.mysql_password
}

locals {
  environments = [
    {
      "name": "DJANGO_SETTINGS_MODULE",
      "value": "byfs.settings.develop"
    }
  ]

  secrets = [
    {
      "name": "BYFS_DB_DEVELOP_HOST",
      "valueFrom": aws_secretsmanager_secret.mysql_host.arn
    },
    {
      "name": "BYFS_DB_DEVELOP_PORT",
      "valueFrom": aws_secretsmanager_secret.mysql_port.arn
    },
    {
      "name": "BYFS_DB_DEVELOP_NAME",
      "valueFrom": aws_secretsmanager_secret.mysql_name.arn
    },
    {
      "name": "BYFS_DB_DEVELOP_USER",
      "valueFrom": aws_secretsmanager_secret.mysql_username.arn
    },
    {
      "name": "BYFS_DB_DEVELOP_PASSWORD",
      "valueFrom": aws_secretsmanager_secret.mysql_password.arn
    }
  ]
}

data template_file task_definition {
  template = <<EOF
{
  "family": "ecs-byfs-development-task-definition",
  "executionRoleArn": "arn:aws:iam::869061964712:role/iam-role-byfs-ecs-execution",
  "networkMode": "awsvpc",
  "containerDefinitions": [
    {
      "name": "django",
      "image": "ghilbut/byfs",
      "essential": true,
      "portMappings": [
        {
          "protocol": "tcp",
          "containerPort": 8000
        }
      ],
      "entryPoint": ["./manage.py", "runserver", "0:8000"],
      "environment": $${environments},
      "secrets": $${secrets}
    }
  ],
  "requiresCompatibilities": [
    "FARGATE"
  ],
  "cpu": "256",
  "memory": "512"
}
EOF

  vars = {
    environments = jsonencode(local.environments)
    secrets = jsonencode(local.secrets)
  }
}

resource local_file task_definition {
  sensitive_content = data.template_file.task_definition.rendered
  filename = "${path.module}/../../../django/${terraform.workspace}-task-definition.json"
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
    "image": "ghilbut/byfs:latest",
    "essential": true,
    "portMappings": [
      {
        "protocol": "tcp",
        "containerPort": 8000
      }
    ],
    "entryPoint": ["./manage.py", "runserver", "0:8000"],
    "environment": [
      {
        "name": "DJANGO_SETTINGS_MODULE",
        "value": "byfs.settings.develop"
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
    container_port   = 8000
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


# https://aws.amazon.com/ko/premiumsupport/knowledge-center/ecs-data-security-container-task/
resource aws_iam_policy secret_access_policy {
  name        = "test-policy"
  description = "A test policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameters",
        "secretsmanager:GetSecretValue"
      ],
      "Resource": [
        "arn:aws:ssm:ap-northeast-2:*:parameter/*",
        "arn:aws:secretsmanager:ap-northeast-2:*:secret:*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "secrets" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = aws_iam_policy.secret_access_policy.arn
}
