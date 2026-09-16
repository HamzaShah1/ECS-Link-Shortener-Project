resource "aws_ecs_cluster" "cluster" {
  name = "url-shortener-cluster"
}

resource "aws_ecr_repository" "api" {
  name = "ecr-api-repo"
  force_delete = true
}

resource "aws_ecr_repository" "dashboard" {
  name = "ecr-dashboard-repo"
  force_delete = true
}

resource "aws_ecr_repository" "worker" {
  name = "ecr-worker-repo"
  force_delete = true
}

resource "aws_cloudwatch_log_group" "api" {
  name = "/ecs/api"
}

resource "aws_cloudwatch_log_group" "dashboard" {
  name = "/ecs/dashboard"
}

resource "aws_cloudwatch_log_group" "worker" {
  name = "/ecs/worker"
}

resource "aws_ecs_task_definition" "api" {
  family                   = "api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.api_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "api"
      image = "${aws_ecr_repository.api.repository_url}:latest"

      cpu    = 256
      memory = 512

      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.api.name
          awslogs-region        = "eu-west-2"
          awslogs-stream-prefix = "api"
        }
      }
      secrets = [
        {
          name      = "DATABASE_URL"
          valueFrom = data.aws_secretsmanager_secret.database_url.arn
        }
      ]

      environment = [
        {
          name  = "SQS_QUEUE_URL"
          value = aws_sqs_queue.click_events.url
        },
        {
          name  = "REDIS_URL"
          value = "redis://${aws_elasticache_cluster.redis.cache_nodes[0].address}:6379"
        }
      ]
    }
  ])
}

resource "aws_ecs_task_definition" "dashboard" {
  family                   = "dashboard"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.dashboard_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "dashboard"
      image = "${aws_ecr_repository.dashboard.repository_url}:latest"

      cpu    = 256
      memory = 512

      portMappings = [
        {
          containerPort = 8081
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.dashboard.name
          awslogs-region        = "eu-west-2"
          awslogs-stream-prefix = "dashboard"
        }
      }
      secrets = [
        {
          name      = "DATABASE_URL"
          valueFrom = data.aws_secretsmanager_secret.database_url.arn
        }
      ]

    }
  ])
}

resource "aws_ecs_task_definition" "worker" {
  family                   = "worker"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.worker_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "worker"
      image = "${aws_ecr_repository.worker.repository_url}:latest"

      cpu    = 256
      memory = 512

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.worker.name
          awslogs-region        = "eu-west-2"
          awslogs-stream-prefix = "worker"
        }
      }
      environment = [
        {
          name  = "SQS_QUEUE_URL"
          value = aws_sqs_queue.click_events.url
        }
      ]

      secrets = [
        {
          name      = "DATABASE_URL"
          valueFrom = data.aws_secretsmanager_secret.database_url.arn
        }
      ]

    }
  ])
}

resource "aws_ecs_service" "api" {
  name            = "api"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = 1

  launch_type = "FARGATE"

  network_configuration {
    subnets = [
      aws_subnet.subnet_2.id,
      aws_subnet.subnet_4.id
    ]

    security_groups = [
      aws_security_group.ecs_security_group.id
    ]

    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "api"
    container_port   = 8080
  }
}


resource "aws_ecs_service" "dashboard" {
  name            = "dashboard"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.dashboard.arn
  desired_count   = 1

  launch_type = "FARGATE"

  network_configuration {
    subnets = [
      aws_subnet.subnet_2.id,
      aws_subnet.subnet_4.id
    ]

    security_groups = [
      aws_security_group.ecs_security_group.id
    ]

    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.dashboard.arn
    container_name   = "dashboard"
    container_port   = 8081
  }
}

resource "aws_ecs_service" "worker" {
  name            = "worker"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.worker.arn
  desired_count   = 1

  launch_type = "FARGATE"

  network_configuration {
    subnets = [
      aws_subnet.subnet_2.id,
      aws_subnet.subnet_4.id
    ]

    security_groups = [
      aws_security_group.ecs_security_group.id
    ]

    assign_public_ip = false
  }

}