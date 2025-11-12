output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "azdo_access_key_id" {
  value     = aws_iam_access_key.azdo.id
  sensitive = true
}

output "azdo_secret_access_key" {
  value     = aws_iam_access_key.azdo.secret
  sensitive = true
}
