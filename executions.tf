// ECS discards stopped tasks about an hour after they stop. EventBridge copies every task state change
// for this cluster into a log group so task-app execution history outlives that window.
// Nullstone reads it per app (filtered by task family) with the app's deployer identity.
resource "aws_cloudwatch_log_group" "executions" {
  name              = "${local.resource_name}-executions"
  retention_in_days = var.executions_retention_in_days
  tags              = local.tags
}

locals {
  // Provider versions differ on whether log group ARNs carry a trailing ":*"; normalize.
  executions_log_group_arn = trimsuffix(aws_cloudwatch_log_group.executions.arn, ":*")
}

resource "aws_cloudwatch_event_rule" "executions" {
  name        = "${local.resource_name}-executions"
  description = "Task state changes for ECS cluster ${aws_ecs_cluster.this.name}"
  tags        = local.tags

  event_pattern = jsonencode({
    source        = ["aws.ecs"]
    "detail-type" = ["ECS Task State Change"]
    detail        = { clusterArn = [aws_ecs_cluster.this.arn] }
  })
}

resource "aws_cloudwatch_event_target" "executions" {
  rule = aws_cloudwatch_event_rule.executions.name
  arn  = local.executions_log_group_arn
}

// EventBridge can only write to a log group through a CloudWatch Logs resource policy.
// AWS allows 10 resource policies per region per account, so this lives on the cluster, not per app.
resource "aws_cloudwatch_log_resource_policy" "executions" {
  policy_name     = "${local.resource_name}-executions"
  policy_document = data.aws_iam_policy_document.executions_log_policy.json
}

data "aws_iam_policy_document" "executions_log_policy" {
  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${local.executions_log_group_arn}:*"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com", "delivery.logs.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudwatch_event_rule.executions.arn]
    }
  }
}
