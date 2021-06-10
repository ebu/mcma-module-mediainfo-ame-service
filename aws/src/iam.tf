##################################
# aws_iam_role + aws_iam_policy
##################################

resource "aws_iam_role" "lambda_execution" {
  name               = format("%.64s", "${var.prefix}.${var.aws_region}.lambda-execution")
  path               = var.iam_role_path
  assume_role_policy = jsonencode({
    Version   : "2012-10-17",
    Statement : [
      {
        Sid       : "AllowLambdaAssumingRole"
        Effect    : "Allow"
        Action    : "sts:AssumeRole",
        Principal : {
          "Service" : "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_policy" "lambda_execution" {
  name   = format("%.128s", "${var.prefix}.${var.aws_region}.lambda-execution")
  path   = var.iam_policy_path
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = concat([
      {
        Sid      : "AllowLambdaWritingToLogs"
        Effect   : "Allow",
        Action   : "logs:*",
        Resource : "*"
      },
      {
        Sid      : "ListAndDescribeDynamoDBTables",
        Effect   : "Allow",
        Action   : [
          "dynamodb:List*",
          "dynamodb:DescribeReservedCapacity*",
          "dynamodb:DescribeLimits",
          "dynamodb:DescribeTimeToLive"
        ],
        Resource : "*"
      },
      {
        Sid      : "SpecificTable",
        Effect   : "Allow",
        Action   : [
          "dynamodb:BatchGet*",
          "dynamodb:DescribeStream",
          "dynamodb:DescribeTable",
          "dynamodb:Get*",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:BatchWrite*",
          "dynamodb:CreateTable",
          "dynamodb:Delete*",
          "dynamodb:Update*",
          "dynamodb:PutItem"
        ],
        Resource : [
          aws_dynamodb_table.service_table.arn
        ]
      },
      {
        Sid      : "AllowInvokingWorkerLambda"
        Effect   : "Allow"
        Action   : "lambda:InvokeFunction"
        Resource : "arn:aws:lambda:${var.aws_region}:${var.aws_account_id}:function:${local.worker_lambda_name}"
      },
      {
        Sid      : "AllowInvokingApiGateway"
        Effect   : "Allow"
        Action   : "execute-api:Invoke"
        Resource : "arn:aws:execute-api:*:*:*"
      },
      {
        Sid      = "AllowWritingToOutputBucket"
        Effect   = "Allow",
        Action   = ["s3:GetObject", "s3:PutObject"],
        Resource = "${var.output_bucket != null ? var.output_bucket.arn : aws_s3_bucket.output[0].arn }/mediainfo-ame-service/*"
      },
    ],
    var.output_bucket_encryption_key != null ?
    [{
      Sid      = "AllowUsingEncryptionKey",
      Effect   = "Allow",
      Action   = [
        "kms:Decrypt",
        "kms:GenerateDataKey"
      ]
      Resource = var.output_bucket_encryption_key.arn
    }] : [],
    var.xray_tracing_enabled ?
    [{
      Sid      : "AllowLambdaWritingToXRay"
      Effect   : "Allow",
      Action   : [
        "xray:PutTraceSegments",
        "xray:PutTelemetryRecords"
      ],
      Resource : "*"
    }]: [],
    var.dead_letter_config_target != null ?
    [{
      Effect: "Allow",
      Action: "sqs:SendMessage",
      Resource: var.dead_letter_config_target
    }] : [])
  })
}

resource "aws_iam_role_policy_attachment" "lambda_execution" {
  role       = aws_iam_role.lambda_execution.id
  policy_arn = aws_iam_policy.lambda_execution.arn
}
