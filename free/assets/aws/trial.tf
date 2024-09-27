resource "aws_sns_topic" "trial" {
  name = local.config.sns.trial.topic_name
}

/* API GATEWAY REST API */
resource "aws_api_gateway_rest_api" "trial" {
  name        = local.config.apigw.trial.name
  description = try(local.config.apigw.trial.description, "REST API Gateway from OpenAPI definition")
  body        = data.template_file.trial.rendered
  endpoint_configuration {
    types = try(local.config.apigw.trial.endpoint_configuration_types, ["REGIONAL"])
  }
  tags = local.config.common.tags
}

data "template_file" "trial" {
  template = file(local.config.apigw.trial.openapi_template_path)
  vars = { 
      topic_arn = aws_sns_topic.trial.arn,
      role_arn  = aws_iam_role.trial.arn,
      context_path = try(local.config.apigw.trial.context_path, "submit")
    }
}

resource "aws_api_gateway_deployment" "trial" {
  rest_api_id = aws_api_gateway_rest_api.trial.id
  stage_name  = try(local.config.apigw.trial.stage_name, "dev")
  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.trial.body))
  }
  lifecycle {
    create_before_destroy = true
  }
}

output "trial_invoke_url" {
  value = "${aws_api_gateway_deployment.trial.invoke_url}/${try(local.config.apigw.trial.context_path, "submit")}"
}

/* IAM */
data "aws_iam_policy_document" "trial_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = [for id in local.config.apigw.trial.iam.assume_role_identifiers : id]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "trial_cloudwatch" {
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

data "aws_iam_policy_document" "trial_sns" {
  statement {
    effect    = "Allow"
    resources = [ aws_sns_topic.trial.arn ]
    actions = [
      "sns:Publish"
    ]
  }
}

resource "aws_iam_role" "trial" {
  name               = local.config.sns.trial.topic_name
  assume_role_policy = data.aws_iam_policy_document.trial_assume_role.json
  inline_policy {
    name   = "sns_policy"
    policy = data.aws_iam_policy_document.trial_sns.json
  }
  tags = local.config.common.tags
}