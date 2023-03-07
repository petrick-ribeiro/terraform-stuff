output "function_name" {
  description = "Lambda function Name"

  value = aws_lambda_function.lambda_chat.function_name
}

output "base_url" {
  description = "Endpoint"

  value = aws_apigatewayv2_stage.chat_stage.invoke_url
}
