resource "aws_iam_role" "eks_admin" {
  name = "${var.project}-eks-admin"

  assume_role_policy = data.aws_iam_policy_document.eks_admin.json
}

data "aws_iam_policy_document" "eks_admin" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}
