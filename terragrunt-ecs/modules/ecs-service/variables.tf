variable "name" {
  description = "Service name, used as a prefix for all resources."
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod...)."
  type        = string
}

# --- Networking / cluster (existing infra, passed in) ---------------------------

variable "cluster_arn" {
  description = "ARN of an existing ECS cluster."
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  description = "Private subnets for the tasks."
  type        = list(string)
}

variable "assign_public_ip" {
  type    = bool
  default = false
}

variable "allowed_ingress_cidrs" {
  description = "CIDRs allowed to reach the container port (e.g. VPC CIDR or ALB)."
  type        = list(string)
  default     = []
}

# --- Container ---------------------------------------------------------------

variable "image" {
  type    = string
  default = "public.ecr.aws/nginx/nginx:stable"
}

variable "container_port" {
  type    = number
  default = 80
}

variable "cpu" {
  description = "Task CPU units (256, 512, 1024...)."
  type        = number
  default     = 256
}

variable "memory" {
  description = "Task memory in MiB."
  type        = number
  default     = 512
}

variable "environment_variables" {
  description = "Extra plain env vars for the container."
  type        = map(string)
  default     = {}
}

variable "log_retention_days" {
  type    = number
  default = 7
}

variable "use_fargate_spot" {
  description = "Run on FARGATE_SPOT instead of FARGATE (cheaper, for non-prod)."
  type        = bool
  default     = false
}

# --- Secret ------------------------------------------------------------------

variable "secret_arn" {
  description = "ARN of the Secrets Manager secret the app reads."
  type        = string
}

variable "secret_env_name" {
  description = "Env var name the secret is exposed as inside the container."
  type        = string
  default     = "APP_SECRET"
}

variable "secret_kms_key_arn" {
  description = "KMS key used to encrypt the secret, if it's a customer managed key."
  type        = string
  default     = null
}

# --- Redis (existing ElastiCache replication group) ---------------------------

variable "redis_endpoint" {
  description = "Primary endpoint of the ElastiCache replication group."
  type        = string
}

variable "redis_port" {
  type    = number
  default = 6379
}

variable "redis_security_group_id" {
  description = "If set, an ingress rule is added to this SG allowing the service to reach Redis."
  type        = string
  default     = null
}

# --- Scaling -----------------------------------------------------------------

variable "desired_count" {
  type    = number
  default = 1
}

variable "min_capacity" {
  type    = number
  default = 1
}

variable "max_capacity" {
  type    = number
  default = 2
}

variable "cpu_target_value" {
  description = "Target average CPU utilization (%) for target tracking."
  type        = number
  default     = 60
}

variable "scale_in_cooldown" {
  type    = number
  default = 300
}

variable "scale_out_cooldown" {
  type    = number
  default = 60
}

variable "tags" {
  type    = map(string)
  default = {}
}
