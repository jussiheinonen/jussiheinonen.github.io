openapi: '3.0.1'
info:
  version: '1.0'
  title: "REST API Gateway and SNS Integration"
paths:
  "/${context_path}":
    post:
      description: "This endpoint delivers to SNS topic"
      responses:
        200:
           description: "Form submission was successful"
        302:
          description: "302 response"
          headers:
            Location:
              schema:
                type: "string"
          content: {}
        400:
           description: "400 Error. Please check logs"
        500:
           description: "500 Error. Please check logs"
      x-amazon-apigateway-integration:
        credentials: "${role_arn}"
        uri: "arn:aws:apigateway:eu-west-1:sns:path//" #This is to make sure any SNS in the eu-west-1 region can be called
        passthroughBehavior: "never"
        httpMethod: "POST"
        type: "aws" #This enables you to redirect the call to this endpoint to an AWS service
        requestParameters:
          integration.request.header.Content-Type: "'application/x-www-form-urlencoded'"
        requestTemplates:
          application/x-www-form-urlencoded: "#set($topic=\"${topic_arn}\")\n#set($msg=$input.body)\nAction=Publish&TopicArn=$util.urlEncode($topic)&Message=$util.urlEncode($msg)"
        responses:
          200: 
            statusCode: "302"
            responseParameters:
              method.response.header.Location: "'https://www.noooner.ltd/submit.html'"
          400:
            statusCode: 400
            responseTemplates:
              application/json: "{\"body\": \"Error: $util.escapeJavaScript($input.path('$.errorMessage'))\"}"
          500:
            statusCode: 500
            responseTemplates:
              application/json: "{\"body\": \"Error: $util.escapeJavaScript($input.path('$.errorMessage'))\"}"
      x-amazon-apigateway-binary-media-types:
        - "multipart/form-data"

