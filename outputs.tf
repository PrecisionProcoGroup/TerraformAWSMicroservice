output "app_url" {
    description = "App URL"
    value = aws_api_gateway_deployment.lambda_api_gateway_deployment[*].invoke_url
}

output "api_key" {
    description = "API Key"
    value = aws_api_gateway_api_key.lambda_api_gateway_api_key[*].value
    sensitive = true
}
