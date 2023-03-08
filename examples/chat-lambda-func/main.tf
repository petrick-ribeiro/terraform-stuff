# Create a Lambda Function to the App.
resource "aws_lambda_function" "lambda_chat" {
  filename      = "${path.module}/lambdas/chat-nodejs.zip"
  function_name = "chat-backend"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.handler"
  runtime       = "nodejs16.x"

  environment {
    variables = {
      API_ENDPOINT = aws_apigatewayv2_stage.chat_stage.invoke_url
    }
  }
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_chat.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.chat_ws.execution_arn}/*"
}

# resource "aws_cloudwatch_log_group" "chat-backend" {
#   name = "/aws/lambda/${aws_lambda_function.lambda_chat.function_name}"

#   retention_in_days = 30
# }

data "archive_file" "lambda_chat_nodejs" {
  type = "zip"

  source_dir  = "${path.module}/lambdas/chat-nodejs/"
  output_path = "${path.module}/lambdas/chat-nodejs.zip"
}

# Create a Websocket to the App.
resource "aws_apigatewayv2_api" "chat_ws" {
  name                       = "chat_api"
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
}

resource "aws_apigatewayv2_stage" "chat_stage" {
  api_id = aws_apigatewayv2_api.chat_ws.id

  name        = "production"
  auto_deploy = true
}

# Integrate with the Lambda Funtion
resource "aws_apigatewayv2_integration" "chat-integration" {
  api_id = aws_apigatewayv2_api.chat_ws.id

  integration_uri  = aws_lambda_function.lambda_chat.invoke_arn
  integration_type = "AWS_PROXY"
}

# Define App routes
resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.chat_ws.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.chat-integration.id}"
}

resource "aws_apigatewayv2_route" "connect" {
  api_id    = aws_apigatewayv2_api.chat_ws.id
  route_key = "$connect"
  target    = "integrations/${aws_apigatewayv2_integration.chat-integration.id}"
}

resource "aws_apigatewayv2_route" "disconnect" {
  api_id    = aws_apigatewayv2_api.chat_ws.id
  route_key = "$disconnect"
  target    = "integrations/${aws_apigatewayv2_integration.chat-integration.id}"
}

resource "aws_apigatewayv2_route" "public" {
  api_id    = aws_apigatewayv2_api.chat_ws.id
  route_key = "sendPublic"
  target    = "integrations/${aws_apigatewayv2_integration.chat-integration.id}"
}

resource "aws_apigatewayv2_route" "private" {
  api_id    = aws_apigatewayv2_api.chat_ws.id
  route_key = "sendPrivate"
  target    = "integrations/${aws_apigatewayv2_integration.chat-integration.id}"
}

resource "aws_apigatewayv2_route" "bot" {
  api_id    = aws_apigatewayv2_api.chat_ws.id
  route_key = "sendBot"
  target    = "integrations/${aws_apigatewayv2_integration.chat-integration.id}"
}

resource "aws_apigatewayv2_route" "name" {
  api_id    = aws_apigatewayv2_api.chat_ws.id
  route_key = "setName"
  target    = "integrations/${aws_apigatewayv2_integration.chat-integration.id}"
}
