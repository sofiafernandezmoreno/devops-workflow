data "aws_caller_identity" "current" {}

resource "aws_iam_user" "azdo" {
  name = "${var.project}-azdo"
  tags = { Project = var.project }
}

resource "aws_iam_user_policy" "azdo_policy" {
  name = "azdo-ci-policy"
  user = aws_iam_user.azdo.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "ecr:*",
          "eks:DescribeCluster",
          "sts:GetCallerIdentity"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_access_key" "azdo" {
  user = aws_iam_user.azdo.name
}
