<!-- BEGIN_TF_DOCS -->



## Resources

No resources.
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| admin\_cidrs | CIDRs allowed to access the EKS public endpoint. | `list(string)` | n/a | yes |
| aws\_region | AWS region. | `string` | n/a | yes |
| project | Base project name. | `string` | n/a | yes |
| subnet\_ids | Subnet IDs. | `list(string)` | n/a | yes |
| vpc\_id | VPC ID. | `string` | n/a | yes |
## Outputs

| Name | Description |
|------|-------------|
| cluster\_name | EKS cluster name. |
<!-- END_TF_DOCS -->