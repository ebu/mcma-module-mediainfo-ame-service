output "service_definition" {
  value = {
    name         = var.name
    auth_type    = local.service_auth_type
    resources    = [
      {
        resource_type = "JobAssignment"
        http_endpoint = "${local.service_url}/job-assignments"
      }
    ]
    job_type     = "AmeJob"
    job_profiles = [{
      name              = "ExtractTechnicalMetadata"
      input_parameters  = [{
        parameter_name = "inputFile"
        parameter_type = "S3Locator"
      }]
      optional_input_parameters = []
      output_parameters = [{
        parameter_name = "outputFile"
        parameter_type = "S3Locator"
      }]
    }]
  }
}

output "aws_iam_role" {
  value = {
    lambda_execution: aws_iam_role.lambda_execution
  }
}

output "aws_iam_policy" {
  value = {
    lambda_execution: aws_iam_policy.lambda_execution
  }
}

output "aws_iam_role_policy_attachment" {
  value = {
    lambda_execution: aws_iam_role_policy_attachment.lambda_execution
  }
}

output "aws_dynamodb_table" {
  value = {
    service_table: aws_dynamodb_table.service_table
  }
}

output "aws_lambda_function" {
  value = {
    api_handler: aws_lambda_function.api_handler
    worker: aws_lambda_function.worker
  }
}

output "aws_apigatewayv2_api" {
  value = {
    service_api: aws_apigatewayv2_api.service_api
  }
}

output "aws_apigatewayv2_integration" {
  value = {
    service_api: aws_apigatewayv2_integration.service_api
  }
}

output "aws_apigatewayv2_route" {
  value = {
    service_api_default: aws_apigatewayv2_route.service_api_default
    service_api_options: aws_apigatewayv2_route.service_api_options
  }
}

output "aws_lambda_permission" {
  value = {
    service_api_default: aws_lambda_permission.service_api_default
    service_api_options: aws_lambda_permission.service_api_options
  }
}

output "aws_apigatewayv2_stage" {
  value = {
    service_api: aws_apigatewayv2_stage.service_api
  }
}
