<!-- BEGIN_TF_DOCS -->



## Resources

| Name | Type |
|------|------|
| [aws_subnets.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_vpc.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aws\_region | n/a | `string` | n/a | yes |
| project | n/a | `string` | n/a | yes |
| use\_default\_vpc | n/a | `bool` | n/a | yes |
## Outputs

| Name | Description |
|------|-------------|
| subnet\_ids | n/a |
| vpc\_id | n/a |
<!-- END_TF_DOCS -->