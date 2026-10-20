include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "envcommon" {
  path   = "${dirname(find_in_parent_folders("root.hcl"))}/_envcommon/ecs-service.hcl"
  expose = true
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
}

# Prod: pinned image, bigger tasks, on-demand Fargate, HA, scales earlier.
inputs = {
  image  = "public.ecr.aws/nginx/nginx:1.27"
  cpu    = 1024
  memory = 2048

  use_fargate_spot   = false
  desired_count      = 3
  min_capacity       = 3
  max_capacity       = 10
  cpu_target_value   = 50
  scale_out_cooldown = 30
  log_retention_days = 90

  secret_kms_key_arn = local.env.app_secret_kms_key
}
