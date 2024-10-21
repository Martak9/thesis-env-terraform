resource "aws_cloudwatch_metric_alarm" "lambda_dynamoDB_allarm" {
    alarm_name = "${var.project_name}-${var.env}-lambda_dynamoDB_allarm"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods = 1
    metric_name = "Errors"
    namespace = "AWS/Lambda"
    period = 60
    statistic = "Average"
    threshold = 0
    alarm_description = "Monitoring lambda_dynamoDB errors"
    dimensions = {
      FunctionName = aws_lambda_function.lambda_dynamoDB.function_name
    }
    actions_enabled = true
}