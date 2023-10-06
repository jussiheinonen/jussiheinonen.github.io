resource "aws_api_gateway_rest_api" "openapi" {
  name        = local.config.apigw.name
  description = try(local.config.apigw.description, "REST API Gateway from OpenAPI definition")
  body        = data.template_file.openapi.rendered
  endpoint_configuration {
    types = try(local.config.apigw.endpoint_configuration_types, ["REGIONAL"])
  }
  tags = local.config.common.tags
}

data "template_file" "openapi" {
  template = file(local.config.apigw.openapi_template_path)
  vars = { 
      topic_arn = aws_sns_topic.this.arn,
      role_arn  = aws_iam_role.this.arn,
      context_path = try(local.config.apigw.context_path, "submit")
    }
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.openapi.id
  stage_name  = try(local.config.apigw.stage_name, "dev")
  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.openapi.body))
  }
  lifecycle {
    create_before_destroy = true
  }
}


output "url" {
  value = "${aws_api_gateway_deployment.this.invoke_url}/${try(local.config.apigw.context_path, "submit")}"
}

output "openapi_template" {
  value = data.template_file.openapi.rendered
}