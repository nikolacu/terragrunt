locals {
  full_name = "${var.name}-${var.environment}"

  tags = merge(var.tags, {
    Service     = var.name
    Environment = var.environment
    ManagedBy   = "terragrunt"
  })

  container_env = merge(var.environment_variables, {
    APP_ENV    = var.environment
    REDIS_HOST = var.redis_endpoint
    REDIS_PORT = tostring(var.redis_port)
    REDIS_URL  = "rediss://${var.redis_endpoint}:${var.redis_port}"
  })
}

data "aws_region" "current" {}

# --- Logs --------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${local.full_name}"
  retention_in_days = var.log_retention_days
  tags              = local.tags
}

# --- IAM: execution role (pulls image, writes logs, reads the secret) ---------

data "aws_iam_policy_document" "ecs_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "execution" {
  name               = "${local.full_name}-exec"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "execution_managed" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "read_secret" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [var.secret_arn]
  }

  dynamic "statement" {
    for_each = var.secret_kms_key_arn == null ? [] : [var.secret_kms_key_arn]
    content {
      actions   = ["kms:Decrypt"]
      resources = [statement.value]
    }
  }
}

resource "aws_iam_role_policy" "read_secret" {
  name   = "read-app-secret"
  role   = aws_iam_role.execution.id
  policy = data.aws_iam_policy_document.read_secret.json
}

# --- IAM: task role (what the app itself can do; empty for now) --------------

resource "aws_iam_role" "task" {
  name               = "${local.full_name}-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
  tags               = local.tags
}

# --- Security group ------------------------------------------------------------

resource "aws_security_group" "service" {
  name        = "${local.full_name}-svc"
  description = "ECS service ${local.full_name}"
  vpc_id      = var.vpc_id
  tags        = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "app" {
  for_each = toset(var.allowed_ingress_cidrs)

  security_group_id = aws_security_group.service.id
  cidr_ipv4         = each.value
  from_port         = var.container_port
  to_port           = var.container_port
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.service.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# Let the service reach the existing Redis replication group.
resource "aws_vpc_security_group_ingress_rule" "redis_from_service" {
  count = var.redis_security_group_id == null ? 0 : 1

  security_group_id            = var.redis_security_group_id
  referenced_security_group_id = aws_security_group.service.id
  from_port                    = var.redis_port
  to_port                      = var.redis_port
  ip_protocol                  = "tcp"
  description                  = "Redis from ${local.full_name}"
}

# --- Task definition -------------------------------------------------------------

resource "aws_ecs_task_definition" "this" {
  family                   = local.full_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name      = var.name
      image     = var.image
      essential = true

      portMappings = [{
        containerPort = var.container_port
        protocol      = "tcp"
      }]

      environment = [
        for k, v in local.container_env : { name = k, value = v }
      ]

      # ECS injects the secret value at task start; the app just reads an env var.
      secrets = [{
        name      = var.secret_env_name
        valueFrom = var.secret_arn
      }]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-region        = data.aws_region.current.region
          awslogs-stream-prefix = var.name
        }
      }
    }
  ])

  tags = local.tags
}

# --- Service -----------------------------------------------------------------

resource "aws_ecs_service" "this" {
  name            = local.full_name
  cluster         = var.cluster_arn
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count

  capacity_provider_strategy {
    capacity_provider = var.use_fargate_spot ? "FARGATE_SPOT" : "FARGATE"
    weight            = 1
  }

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.service.id]
    assign_public_ip = var.assign_public_ip
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  # Autoscaling owns desired_count after the first apply.
  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = local.tags
}
