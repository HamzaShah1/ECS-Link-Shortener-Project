resource "aws_elasticache_subnet_group" "redis" {
  name = "redis-subnet-group"

  subnet_ids = [
    aws_subnet.subnet_2.id,
    aws_subnet.subnet_4.id
  ]
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "url-shortener-redis"
  engine               = "redis"
  node_type            = "cache.t4g.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379

  subnet_group_name = aws_elasticache_subnet_group.redis.name

  security_group_ids = [
    aws_security_group.redis_security_group.id
  ]
}