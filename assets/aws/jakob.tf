resource "aws_sns_topic" "jakob" {
  name = local.config.sns.jakob.topic_name
}

/* API GATEWAY REST API */
resource "aws_api_gateway_rest_api" "jakob" {
  name        = local.config.apigw.jakob.name
  description = try(local.config.apigw.jakob.description, "REST API Gateway from OpenAPI definition")
  body        = data.template_file.jakob.rendered
  endpoint_configuration {
    types = try(local.config.apigw.jakob.endpoint_configuration_types, ["REGIONAL"])
  }
  tags = local.config.common.tags
}

data "template_file" "jakob" {
  template = file(local.config.apigw.jakob.openapi_template_path)
  vars = { 
      topic_arn = aws_sns_topic.jakob.arn,
      role_arn  = aws_iam_role.jakob.arn,
      context_path = try(local.config.apigw.jakob.context_path, "submit")
    }
}

resource "aws_api_gateway_deployment" "jakob" {
  rest_api_id = aws_api_gateway_rest_api.jakob.id
  stage_name  = try(local.config.apigw.jakob.stage_name, "dev")
  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.jakob.body))
  }
  lifecycle {
    create_before_destroy = true
  }
}

output "jakob_invoke_url" {
  value = "${aws_api_gateway_deployment.jakob.invoke_url}/${try(local.config.apigw.jakob.context_path, "submit")}"
}

/* IAM */
data "aws_iam_policy_document" "jakob_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = [for id in local.config.apigw.jakob.iam.assume_role_identifiers : id]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "jakob_cloudwatch" {
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

data "aws_iam_policy_document" "jakob_sns" {
  statement {
    effect    = "Allow"
    resources = [ aws_sns_topic.jakob.arn ]
    actions = [
      "sns:Publish"
    ]
  }
}

resource "aws_iam_role" "jakob" {
  name               = local.config.sns.jakob.topic_name
  assume_role_policy = data.aws_iam_policy_document.jakob_assume_role.json
  inline_policy {
    name   = "sns_policy"
    policy = data.aws_iam_policy_document.jakob_sns.json
  }
  tags = local.config.common.tags
}