output "api_id" {
  description = "The ID of the created HTTP API"
  value       = aws_apigatewayv2_api.this.id
}

output "api_endpoint" {
  description = "The endpoint of the created HTTP API"
  value       = aws_apigatewayv2_api.this.api_endpoint
}

output "stage_name" {
  description = "The name of the stage"
  value       = aws_apigatewayv2_stage.this.name
}
