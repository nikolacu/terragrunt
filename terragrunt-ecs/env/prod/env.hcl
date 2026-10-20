# Everything that identifies the prod environment.
locals {
  environment = "prod"
  account_id  = "222222222222"
  aws_region  = "eu-central-1"

  cluster_arn        = "arn:aws:ecs:eu-central-1:222222222222:cluster/prod"
  vpc_id             = "vpc-p000000000000000"
  vpc_cidr           = "10.20.0.0/16"
  private_subnet_ids = ["subnet-0000000000000000a", "subnet-0000000000000000b", "subnet-0000000000000000c"]

  redis_endpoint          = "master.app-prod.xyz789.euc1.cache.amazonaws.com"
  redis_security_group_id = "sg-prodredis00000000"

  app_secret_arn     = "arn:aws:secretsmanager:eu-central-1:222222222222:secret:/prod/app/secret-GhIjKl"
  app_secret_kms_key = "arn:aws:kms:eu-central-1:222222222222:key/00000000-0000-0000-0000-000000000000"
}
