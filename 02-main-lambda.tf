data "archive_file" "zip_lambda_dynamo" {
  type        = "zip"
  output_path = "./lambda_code/dynamoDB_lambda.zip"
  source_file  = "./lambda_code/dynamoDB_lambda.py"
}


resource "aws_lambda_function" "lambda_dynamoDB" {
    filename      = "${path.module}/lambda_code/dynamoDB_lambda.zip"
    function_name = "${var.project_name}-${var.env}-dynamoDB_lambda"
    handler       = "dynamoDB_lambda.lambda_handler"
    runtime       = "python3.12"
    role          = aws_iam_role.lambda_dynamo_role.arn
    timeout       = 60

    source_code_hash = data.archive_file.zip_lambda_dynamo.output_base64sha256


    layers = [
        "arn:aws:lambda:${var.region}:336392948345:layer:AWSSDKPandas-Python312:1"
    ]
    environment {
        variables = {
        DYNAMODB_TABLE_NAME = aws_dynamodb_table.thesis-dynamo-table.name
        }
    }
}

resource "aws_lambda_function_event_invoke_config" "lambda_dynamoDB_config" {
  function_name                = aws_lambda_function.lambda_dynamoDB.function_name
  maximum_event_age_in_seconds = 60
  maximum_retry_attempts       = 0
}

#------------------------------------------------------------------------------------------
data "archive_file" "zip_lambda_error" {
  type        = "zip"
  output_path = "./lambda_code/lambda_message_and_error_triggered.zip"
  source_file  = "./lambda_code/lambda_message_and_error_triggered.py"
}

resource "aws_lambda_function" "lambda_message_and_error_triggered" {
    filename      = "${path.module}/lambda_code/lambda_message_and_error_triggered.zip"
    function_name = "${var.project_name}-${var.env}-message_and_error_triggered_lambda"
    handler       = "lambda_message_and_error_triggered.lambda_handler"
    runtime       = "python3.12"
    role          = aws_iam_role.lambda_error_role.arn
    timeout       = 60   

    source_code_hash = data.archive_file.zip_lambda_error.output_base64sha256

    environment {
    variables = {
        LAMBDA_FUNCTION_NAME = "thesis-env-dynamoDB_lambda"
        LOG_GROUP_NAME = "/aws/lambda/${var.project_name}-${var.env}-dynamoDB_lambda"
        TOPIC_ARN = aws_sns_topic.error_topic.arn
        KB_ID = aws_bedrockagent_knowledge_base.bedrockKB.id
        MODEL_ID = "anthropic.claude-3-5-sonnet-20240620-v1:0"
    }
  }
}

resource "aws_lambda_function_event_invoke_config" "lambda_message_and_error_triggered_config" {
  function_name                = aws_lambda_function.lambda_message_and_error_triggered.function_name
  maximum_event_age_in_seconds = 60
  maximum_retry_attempts       = 0
}