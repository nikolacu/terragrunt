# Everything that identifies the dev environment.
locals {
  environment = "dev"
  account_id  = "111111111111"
  aws_region  = "eu-central-1"

  cluster_arn        = "arn:aws:ecs:eu-central-1:111111111111:cluster/dev"
  vpc_id             = "vpc-d000000000000000"
  vpc_cidr           = "10.10.0.0/16"
  private_subnet_ids = ["subnet-0000000000000000a", "subnet-0000000000000000b"]

  redis_endpoint          = "master.app-dev.abc123.euc1.cache.amazonaws.com"
  redis_security_group_id = "sg-devredis000000000"

  app_secret_arn = "arn:aws:secretsmanager:eu-central-1:111111111111:secret:/dev/app/secret-AbCdEf"
}
