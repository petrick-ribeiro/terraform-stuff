data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type         = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "chatbot_nodejs"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# Create a Websocket to the App.
resource "aws_apigatewayv2_api" "chatbot_ws" {
  name = "chatbot_api"
  protocol_type = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
}

# Define App routes
resource "aws_apigatewayv2_route" "public" {
  api_id = aws_apigatewayv2_api.chatbot_ws.id
  route_key = "sendPublic"
  target = "integrations/${aws_apigatewayv2_integration.chatbot-integration.id}"
}

resource "aws_apigatewayv2_route" "private" {
  api_id = aws_apigatewayv2_api.chatbot_ws.id
  route_key = "sendPrivate"
  target = "integrations/${aws_apigatewayv2_integration.chatbot-integration.id}"
}

resource "aws_apigatewayv2_route" "bot" {
  api_id = aws_apigatewayv2_api.chatbot_ws.id
  route_key = "sendBot"
  target = "integrations/${aws_apigatewayv2_integration.chatbot-integration.id}"
}

resource "aws_apigatewayv2_route" "name" {
  api_id = aws_apigatewayv2_api.chatbot_ws.id
  route_key = "sendName"
  target = "integrations/${aws_apigatewayv2_integration.chatbot-integration.id}"
}

# Integrate with the Lambda Funtion
resource "aws_apigatewayv2_integration" "chatbot-integration" {
  api_id = aws_apigatewayv2_api.chatbot_ws.id
  integration_type = "AWS_PROXY"

  connection_type = "INTERNET"
  content_handling_strategy = "CONVERT_TO_TEXT"
  integration_method = "POST"
  integration_uri = aws_lambda_function.lambda_chatbot.invoke_arn
  passthrough_behavior = "WHEN_NO_MATCH"
}

# Create a Lambda Function to the App.
resource "aws_lambda_function" "lambda_chatbot" {
  filename      = "./chatbot-nodejs.zip"
  function_name = "ChatBot-Backend"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "index.js"
  runtime       = "nodejs16.x"

  environment {
    variables = {
      foo = "bar"
    }
  }
}
