data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = [for id in local.config.apigw.iam.assume_role_identifiers : id]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "cloudwatch" {
  statement {
    effect = "Allow"
    resources = [
      "arn:aws:logs:*:*:*"
    ]
    actions = [
      "logs:*"
    ]
  }
}

data "aws_iam_policy_document" "sns" {
  statement {
    effect    = "Allow"
    resources = [ aws_sns_topic.this.arn ]
    actions = [
      "sns:Publish"
    ]
  }
}

resource "aws_iam_role" "this" {
  name               = local.config.sns.topic_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  inline_policy {
    name   = "sns_policy"
    policy = data.aws_iam_policy_document.sns.json
  }
  tags = local.config.common.tags
}