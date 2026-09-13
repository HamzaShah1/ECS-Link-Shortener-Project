resource "aws_lb" "alb" {
  name               = "alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_security_group.id]
  subnets            = [aws_subnet.subnet_1.id, aws_subnet.subnet_3.id]
}

resource "aws_lb_target_group" "api" {
  name        = "api-target-group"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id
  target_type = "ip"
}

resource "aws_lb_target_group" "dashboard" {
  name        = "dashboard-target-group"
  port        = 8081
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id
  target_type = "ip"
}

resource "aws_acm_certificate" "certificate" {
  domain_name       = "hamza-aws-project.com"
  validation_method = "DNS"
}