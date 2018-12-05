provider "aws" {
  region     = "us-east-1"
}

resource "aws_lambda_function" "py_lambda_1" {
  function_name = "py_lambda_1"

  s3_bucket = "py-api-1"
  s3_key    = "py-api-v0.zip"

  handler = "main.handler"
  runtime = "python2.7"
  memory_size = "256"
  role = "${aws_iam_role.py_lambda_1_role.arn}"
}

resource "aws_iam_role" "py_lambda_1_role" {
  name = "py_lambda_1_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
      "Action": "sts:AssumeRole",
      "Principal": {
          "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
      }
  ]
}
EOF
}

resource "aws_iam_policy" "py_lambda_1_cloudwatch" {
  name = "py_lambda_1_cloudwatch"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
        "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
        "Resource": "*",
        "Effect": "Allow"
      }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "auth_lambda_cloudwatch" {
  role = "${aws_iam_role.py_lambda_1_role.name}"
  policy_arn = "${aws_iam_policy.py_lambda_1_cloudwatch.arn}"
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.py_lambda_1.arn}"
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_deployment.deployment.execution_arn}/*/*"
}


resource "aws_lambda_function" "authorizer" {
  function_name = "authorizer"

  s3_bucket = "py-api-1"
  s3_key    = "authorizer-v0.zip"

  handler = "authorizer.handler"
  runtime = "python2.7"
  memory_size = "256"
  role = "${aws_iam_role.py_lambda_1_role.arn}"
}

