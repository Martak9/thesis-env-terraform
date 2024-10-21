resource "aws_cloudwatch_event_rule" "cloudwatch_lambda_error_trigger" {
  name        = "${var.project_name}-${var.env}-lambda-error-trigger"
  description = "Regola EventBridge per attivarsi quando la Lambda va in errore"
  event_pattern = jsonencode({
    "source": ["aws.cloudwatch"],
    "detail-type": ["CloudWatch Alarm State Change"],
    "resources": ["arn:aws:cloudwatch:eu-west-1:523753954008:alarm:thesis-env-lambda_dynamoDB_allarm"],
    "detail": {
        "state": {
        "value": ["ALARM"]
    }
  }
})
}


resource "aws_cloudwatch_event_target" "lambda_on_error_target" {
  rule       = aws_cloudwatch_event_rule.cloudwatch_lambda_error_trigger.name
  target_id  = "trigger-on-error"
  arn        = aws_lambda_function.lambda_message_and_error_triggered.arn
  input_transformer {
    input_paths = {
      "alarmName": "$.detail.alarmName",
      "stateReason": "$.detail.state.reason",
      "stateValue": "$.detail.state.value"
    }
    input_template = replace(replace(jsonencode({
      "header" : "Allarme <alarmName> in stato <stateValue>",
      "message" : "La funzione Lambda dynamoDB_lambda è entrata in errore, quindi l'allarme '<alarmName>' è passato allo stato '<stateValue>' per il seguente motivo: <stateReason>."
    }), "\\u003c", "<"), "\\u003e", ">")
  }
}


# Permessi per invocare la Lambda
resource "aws_lambda_permission" "allow_eventbridge_on_error" {
  statement_id  = "AllowEventBridgeInvocation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_message_and_error_triggered.function_name
  principal     = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.cloudwatch_lambda_error_trigger.arn
}