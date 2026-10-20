# Common config for the "app" ECS service, shared by all environments.
# Each env's terragrunt.hcl includes this and only sets what differs.

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env      = local.env_vars.locals

  module_source = "${dirname(find_in_parent_folders("root.hcl"))}/../modules/ecs-service"
}

terraform {
  source = local.module_source
}

inputs = {
  name           = "nikola"
  container_port = 80

  # Existing shared infra for this environment (from env.hcl)
  cluster_arn             = local.env.cluster_arn
  vpc_id                  = local.env.vpc_id
  subnet_ids              = local.env.private_subnet_ids
  allowed_ingress_cidrs   = [local.env.vpc_cidr]
  redis_endpoint          = local.env.redis_endpoint
  redis_security_group_id = local.env.redis_security_group_id

  # Same secret name convention in every env: /<env>/app/secret
  secret_arn      = local.env.app_secret_arn
  secret_env_name = "APP_SECRET"

  environment_variables = {
    LOG_LEVEL = "info"
  }
}
