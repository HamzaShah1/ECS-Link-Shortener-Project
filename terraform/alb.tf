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

  health_check {
    path = "/healthz"
  }
}

resource "aws_lb_target_group" "dashboard" {
  name        = "dashboard-target-group"
  port        = 8081
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id
  target_type = "ip"

  health_check {
    path = "/healthz"
  }
}

resource "aws_acm_certificate" "certificate" {
  domain_name       = "hamza-aws-project.com"
  validation_method = "DNS"

  subject_alternative_names = [
    "*.hamza-aws-project.com"
  ]
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"

  certificate_arn = aws_acm_certificate.certificate.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}

resource "aws_lb_listener_rule" "dashboard" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  condition {
    host_header {
      values = ["dashboard.hamza-aws-project.com"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dashboard.arn
  }
}