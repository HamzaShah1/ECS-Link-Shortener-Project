resource "aws_ecs_cluster" "cluster" {
  name = "url-shortener-cluster"
}

resource "aws_ecr_repository" "api" {
  name = "ecr-api-repo"
}

resource "aws_ecr_repository" "dashboard" {
  name = "ecr-dashboard-repo"
}

resource "aws_ecr_repository" "worker" {
  name = "ecr-worker-repo"
}