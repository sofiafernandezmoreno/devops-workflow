<!-- BEGIN_TF_DOCS -->



## Resources

No resources.
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aws\_region | AWS region | `string` | `"eu-west-1"` | no |
| ecr\_repo | ECR repository name | `string` | `"springboot-app"` | no |
| project | Project name prefix | `string` | `"nn-devops"` | no |
| use\_default\_vpc | If true, reuse AWS default VPC (recommended for free-tier) | `bool` | `true` | no |
## Outputs

| Name | Description |
|------|-------------|
| aws\_account\_id | n/a |
| azdo\_access\_key\_id | n/a |
| azdo\_secret\_access\_key | n/a |
| ecr\_repository\_url | n/a |
| eks\_cluster\_name | n/a |
| subnet\_ids | n/a |
| vpc\_id | n/a |
<!-- END_TF_DOCS -->