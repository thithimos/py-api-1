resource "aws_api_gateway_rest_api" "py_api_1" {
  name        = "py_api_1"
  description = "This is an API with a Python lambda behind it"
}

resource "aws_api_gateway_authorizer" "api_authorizer" {
  name                           = "api_authorizer"
  rest_api_id                    = "${aws_api_gateway_rest_api.py_api_1.id}"
  authorizer_uri                 = "${aws_lambda_function.authorizer.invoke_arn}"
  authorizer_credentials         = "${aws_iam_role.invocation_role.arn}"
  type                           = "REQUEST"
  identity_validation_expression = "Bearer (.*)"
}

resource "aws_api_gateway_resource" "auth0_test" {
  rest_api_id = "${aws_api_gateway_rest_api.py_api_1.id}"
  parent_id   = "${aws_api_gateway_rest_api.py_api_1.root_resource_id}"
  path_part   = "auth0_test"
}

resource "aws_api_gateway_method" "auth0_test_method" {
  rest_api_id   = "${aws_api_gateway_rest_api.py_api_1.id}"
  resource_id   = "${aws_api_gateway_resource.auth0_test.id}"
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = "${aws_api_gateway_authorizer.api_authorizer.id}"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = "${aws_api_gateway_rest_api.py_api_1.id}"
  resource_id = "${aws_api_gateway_resource.auth0_test.id}"
  http_method = "${aws_api_gateway_method.auth0_test_method.http_method}"
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.py_lambda_1.invoke_arn}"
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    "aws_api_gateway_integration.lambda"
  ]
  rest_api_id = "${aws_api_gateway_rest_api.py_api_1.id}"
  stage_name  = "v0"
}

resource "aws_iam_role" "invocation_role" {
  name = "api_gateway_auth_invocation"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "invocation_policy" {
  name = "default"
  role = "${aws_iam_role.invocation_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "lambda:InvokeFunction",
      "Effect": "Allow",
      "Resource": "${aws_lambda_function.authorizer.arn}"
    }
  ]
}
EOF
}

output "base_url" {
  value = "${aws_api_gateway_deployment.deployment.invoke_url}"
}