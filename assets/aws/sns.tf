resource "aws_sns_topic" "this" {
  name = local.config.sns.topic_name
}

resource "aws_sns_topic_subscription" "this" {
  for_each  = local.config.sns.subscriptions
  topic_arn = aws_sns_topic.this.arn
  protocol  = each.value.protocol
  endpoint  = each.value.endpoint
}

output "sns_subscription_status" {
  value    = [for sub in aws_sns_topic_subscription.this : sub.pending_confirmation]
}