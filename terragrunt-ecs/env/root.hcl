# Root config: every unit under env/ includes this.
# Backend and provider are defined ONCE here and generated per unit.

locals {
  env_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  environment = local.env_vars.locals.environment
  aws_region  = local.env_vars.locals.aws_region
  account_id  = local.env_vars.locals.account_id
}

remote_state {
  backend = "s3"

  config = {
    bucket       = "nikola-tfstate-${local.account_id}"
    key          = "${path_relative_to_include()}/terraform.tfstate"
    region       = local.aws_region
    encrypt      = true
    use_lockfile = true # native S3 locking, no DynamoDB table needed
  }

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "aws" {
      region              = "${local.aws_region}"
      allowed_account_ids = ["${local.account_id}"]

      default_tags {
        tags = {
          Environment = "${local.environment}"
          Repo        = "terragrunt-ecs-demo"
        }
      }
    }
  EOF
}

# Shared defaults; env.hcl and unit-level inputs override these.
inputs = {
  environment = local.environment
}
