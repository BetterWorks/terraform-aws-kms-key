data "aws_caller_identity" "current" {}
module "label" {
  source     = "git::https://github.com/betterworks/terraform-null-label.git?ref=tags/0.13.0"
  namespace  = var.namespace
  stage      = var.stage
  name       = var.name
  attributes = var.attributes
  delimiter  = var.delimiter
  tags       = var.tags
}

resource "aws_kms_key" "default" {
  description             = var.description
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = var.enable_key_rotation
  tags                    = module.label.tags
}

resource "aws_kms_alias" "default" {
  name          = coalesce(var.alias, format("alias/%v", module.label.id))
  target_key_id = aws_kms_key.default.id
}


resource "aws_kms_key_policy" "default" {
  key_id = aws_kms_key.default.id
  policy = data.aws_iam_policy_document.kms_key_policy.json
}

data "aws_iam_policy_document" "kms_key_policy" {

  statement {
    sid       = "AccessibleAWSAccounts"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      identifiers = [for id in var.aws_accounts : "arn:aws:iam::${id}:root"]
      type        = "AWS"
    }
  }
}

local {
  aws_accounts = concat(var.accounts_with_access, [data.aws_caller_identity.current.account_id])
}
