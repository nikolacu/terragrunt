include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "envcommon" {
  path   = "${dirname(find_in_parent_folders("root.hcl"))}/_envcommon/ecs-service.hcl"
  expose = true
}

# Dev: small, cheap, on-demand Fargate, scales a little.
inputs = {
  image  = "public.ecr.aws/nginx/nginx:latest"
  cpu    = 256
  memory = 512

  use_fargate_spot   = false
  desired_count      = 1
  min_capacity       = 1
  max_capacity       = 2
  cpu_target_value   = 75
  log_retention_days = 7

  environment_variables = merge(
    include.envcommon.inputs.environment_variables,
    { LOG_LEVEL = "debug" }
  )
}
