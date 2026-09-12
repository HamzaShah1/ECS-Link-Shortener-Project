resource "aws_security_group" "alb_security_group" {
  name        = "alb_security_group"
  description = "control the inbound and outbound traffic for the ALB"
  vpc_id      = aws_vpc.vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "ingress_rule" {
  security_group_id = aws_security_group.alb_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "egress_rule" {
  security_group_id            = aws_security_group.alb_security_group.id
  referenced_security_group_id = aws_security_group.ecs_security_group.id
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
}

resource "aws_security_group" "ecs_security_group" {
  name        = "ecs_security_group"
  description = "controls traffic to ECS"
  vpc_id      = aws_vpc.vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "ecs_ingress_rule" {
  security_group_id            = aws_security_group.ecs_security_group.id
  referenced_security_group_id = aws_security_group.alb_security_group.id
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
}

resource "aws_security_group" "rds_security_group" {
  name        = "rds_security_group"
  description = "controls traffic to RDS"
  vpc_id      = aws_vpc.vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "rds_ingress_rule" {
  security_group_id            = aws_security_group.rds_security_group.id
  referenced_security_group_id = aws_security_group.ecs_security_group.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
}

resource "aws_security_group" "redis_security_group" {
  name        = "redis_security_group"
  description = "controls traffic to redis"
  vpc_id      = aws_vpc.vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "redis_ingress_rule" {
  security_group_id            = aws_security_group.redis_security_group.id
  referenced_security_group_id = aws_security_group.ecs_security_group.id
  ip_protocol                  = "tcp"
  from_port                    = 6379
  to_port                      = 6379
}