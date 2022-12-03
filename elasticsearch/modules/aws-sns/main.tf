# SNS
resource "aws_sns_topic" "autoscaling-sns" {
  name = var.auto-scaling-sns-name
}

resource "aws_sns_topic_subscription" "aws_sns_topic_subscription" {

  endpoint  = var.sns-subscription-email-address
  protocol  = "email"
  topic_arn = aws_sns_topic.autoscaling-sns.arn
}