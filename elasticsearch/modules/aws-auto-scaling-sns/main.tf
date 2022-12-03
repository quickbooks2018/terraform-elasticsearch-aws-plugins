resource "aws_autoscaling_notification" "aws_autoscaling_notification" {
  group_names = [var.aws_autoscaling_notification]

  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]
  topic_arn = var.sns-topic-arn
  lifecycle {
    create_before_destroy = true
  }
}