resource "aws_sns_topic" "error_topic" {
  name = "${var.project_name}-${var.env}-sns-topic"
}


resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.error_topic.arn
  protocol  = "email"
  endpoint  = "m.paciotti@reply.com"
}