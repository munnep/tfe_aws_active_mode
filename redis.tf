resource "aws_elasticache_subnet_group" "test" {
  name       = "test-patrick"
  subnet_ids = [aws_subnet.private1.id]
}

resource "aws_elasticache_cluster" "example" {
  cluster_id           = "patrick-example"
  engine               = "redis"
  node_type            = "cache.t3.small"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis5.0"
  engine_version       = "5.0.6"
  port                 = 6379
  security_group_ids = [aws_security_group.tfe_server_sg.id]
  subnet_group_name = aws_elasticache_subnet_group.test.name
}

# test connection to Redis

# https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/GettingStarted.ConnectToCacheNode.html
# sudo apt install redis-server

# patrick-example.1yhbvq.0001.eun1.cache.amazonaws.com:6379

# redis-cli -h patrick-example.1yhbvq.0001.eun1.cache.amazonaws.com -c -p 6379




# resource "aws_launch_configuration" "as_conf2" {
#   name_prefix          = "${var.tag_prefix}-lc2"
#   image_id             = var.ami
#   instance_type        = "t3.xlarge"
#   security_groups      = [aws_security_group.tfe_server_sg.id]
#   iam_instance_profile = aws_iam_instance_profile.profile.name
#   key_name             = "${var.tag_prefix}-key"

#   root_block_device {
#     volume_size = 50

#   }

#   ebs_block_device {
#     device_name = "/dev/sdh"
#     volume_size = 32
#     volume_type = "io1"
#     iops        = 1000
#   }

#   ebs_block_device {
#     device_name = "/dev/sdi"
#     volume_size = 100
#     volume_type = "io1"
#     iops        = 2000
#   }


#   user_data = templatefile("${path.module}/scripts/user-data-active-active.sh", {
#     tag_prefix         = var.tag_prefix
#     filename_airgap    = var.filename_airgap
#     filename_license   = var.filename_license
#     filename_bootstrap = var.filename_bootstrap
#     dns_hostname       = var.dns_hostname
#     tfe_password       = var.tfe_password
#     dns_zonename       = var.dns_zonename
#     pg_dbname          = aws_db_instance.default.name
#     pg_address         = aws_db_instance.default.address
#     rds_password       = var.rds_password
#     tfe_bucket         = "${var.tag_prefix}-bucket"
#     region             = var.region
#     redis_server       = aws_elasticache_cluster.example.cluster_address
#   })


#   lifecycle {
#     create_before_destroy = true
#   }
# }