# terragrunt-ecs

Jedan reusable `ecs-service` modul + Terragrunt `env/` struktura za dev i prod.

```
modules/ecs-service/        # čist Terraform modul, ne zna ništa o okruženjima
  main.tf                   # task def, service, SG, IAM, log group
  autoscaling.tf            # target tracking na CPU
  variables.tf / outputs.tf / versions.tf
env/
  root.hcl                  # S3 backend + AWS provider, definisani JEDNOM
  _envcommon/ecs-service.hcl# zajednički inputi za servis u svim okruženjima
  dev/
    env.hcl                 # account, VPC, cluster, redis, secret za dev
    ecs-service/terragrunt.hcl   # samo ono po čemu se dev razlikuje
  prod/
    env.hcl
    ecs-service/terragrunt.hcl
```

## Šta modul radi

- **Secret**: execution role dobija `secretsmanager:GetSecretValue` (+ `kms:Decrypt` ako je CMK),
  a ECS ubacuje vrednost u kontejner kao env var `APP_SECRET` preko `secrets` bloka.
- **Redis**: replication group je postojeći; modul samo prosleđuje `REDIS_HOST/PORT/URL`
  i (opciono) dodaje ingress pravilo na Redis SG iz SG-a servisa.
- **Autoscaling**: `ECSServiceAverageCPUUtilization` target tracking; `desired_count`
  je u `ignore_changes` da apply ne bi gazio ono što je autoscaler podesio.
- Image je nginx, servis je u privatnim subnetima, deployment circuit breaker uključen.

## Dev vs prod

| | dev | prod |
|---|---|---|
| Image | `nginx:latest` | pinovan `nginx:1.27` |
| CPU / mem | 256 / 512 | 1024 / 2048 |
| Kapacitet | FARGATE | FARGATE |
| Tasks min/max | 1 / 2 | 3 / 10 |
| CPU target | 75% | 50%, brži scale-out |
| Log retention | 7 dana | 90 dana |
| Secret KMS | AWS managed | CMK |
| AWS account | 111111111111 | 222222222222 |

## Pokretanje

```bash
cd env/dev/ecs-service && terragrunt plan
cd env/prod/ecs-service && terragrunt apply

# sve odjednom (novije verzije Terragrunta; starije: terragrunt run-all plan)
cd env && terragrunt run --all plan
```

Sve vrednosti u `env.hcl` (ARN-ovi, ID-jevi, account-i) su placeholderi.
