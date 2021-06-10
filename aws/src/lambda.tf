#################################
#  locals
#################################

locals {
  worker_lambda_name = format("%.64s", replace("${var.prefix}-worker", "/[^a-zA-Z0-9_]+/", "-" ))
}

#################################
#  aws_lambda_function : api_handler
#################################

resource "aws_lambda_function" "api_handler" {
  depends_on = [
    aws_iam_role_policy_attachment.lambda_execution
  ]

  filename         = "${path.module}/lambdas/api-handler.zip"
  function_name    = format("%.64s", replace("${var.prefix}-api-handler", "/[^a-zA-Z0-9_]+/", "-" ))
  role             = aws_iam_role.lambda_execution.arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256("${path.module}/lambdas/api-handler.zip")
  runtime          = "nodejs12.x"
  timeout          = "30"
  memory_size      = "2048"

  layers = var.enhanced_monitoring_enabled ? ["arn:aws:lambda:${var.aws_region}:580247275435:layer:LambdaInsightsExtension:14"] : []

  environment {
    variables = {
      LogGroupName     = var.log_group.name
      TableName        = aws_dynamodb_table.service_table.name
      PublicUrl        = local.service_url
      WorkerFunctionId = aws_lambda_function.worker.function_name
    }
  }

  tracing_config {
    mode = var.xray_tracing_enabled ? "Active" : "PassThrough"
  }

  tags = var.tags
}

#################################
#  aws_lambda_function : worker
#################################

resource "aws_lambda_layer_version" "mediainfo" {
  filename         = "${path.module}/layers/MediaInfo_CLI_21.03_Lambda.zip"
  layer_name       = "${var.prefix}-mediainfo-ame-service"
  source_code_hash = filebase64sha256("${path.module}/layers/MediaInfo_CLI_21.03_Lambda.zip")
}

resource "aws_lambda_function" "worker" {
  depends_on = [
    aws_iam_role_policy_attachment.lambda_execution
  ]

  filename         = "${path.module}/lambdas/worker.zip"
  function_name    = local.worker_lambda_name
  role             = aws_iam_role.lambda_execution.arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256("${path.module}/lambdas/worker.zip")
  runtime          = "nodejs12.x"
  timeout          = "900"
  memory_size      = "2048"

  layers = concat(var.enhanced_monitoring_enabled ? ["arn:aws:lambda:${var.aws_region}:580247275435:layer:LambdaInsightsExtension:14"]: [], [aws_lambda_layer_version.mediainfo.arn])

  environment {
    variables = {
      LogGroupName     = var.log_group.name
      TableName        = aws_dynamodb_table.service_table.name
      PublicUrl        = local.service_url
      ServicesUrl      = var.service_registry.services_url
      ServicesAuthType = var.service_registry.auth_type
      OutputBucket     = var.output_bucket != null ? var.output_bucket.id : aws_s3_bucket.output[0].id
    }
  }

  dynamic "dead_letter_config" {
    for_each = var.dead_letter_config_target != null ? toset([1]) : toset([])

    content {
      target_arn = var.dead_letter_config_target
    }
  }

  tracing_config {
    mode = var.xray_tracing_enabled ? "Active" : "PassThrough"
  }

  tags = var.tags
}
