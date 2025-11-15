<!-- BEGIN_TF_DOCS -->



## Resources

No resources.
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| admin\_cidrs | CIDRs allowed to access the EKS public endpoint. | `list(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| aws\_region | AWS region for the deployment | `string` | `"eu-west-1"` | no |
| ecr\_repo | Name of the ECR repository | `string` | `"nn-devops-challenge"` | no |
| project | Project name for tagging and naming | `string` | `"nn-devops-challenge"` | no |
| use\_default\_vpc | Use AWS default VPC instead of creating a new one | `bool` | `true` | no |
## Outputs

| Name | Description |
|------|-------------|
| ecr\_repository\_url | URL of the ECR repository where images are pushed. |
| eks\_cluster\_name | Name of the EKS cluster. |
| subnet\_ids | Subnet IDs used by the EKS cluster. |
| vpc\_id | VPC ID used by the EKS cluster. |
<!-- END_TF_DOCS -->