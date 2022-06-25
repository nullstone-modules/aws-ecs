resource "aws_iam_group" "deployers" {
  name = "deployers-${local.resource_name}"
}

resource "aws_iam_group_policy" "deployers" {
  name   = "deployers-${local.resource_name}"
  group  = aws_iam_group.deployers.id
  policy = data.aws_iam_policy_document.deployer.json
}

data "aws_iam_policy_document" "deployer" {
  statement {
    sid    = "AllowEditTaskDefinitions"
    effect = "Allow"

    actions = [
      "ecs:DescribeTaskDefinition",
      "ecs:RegisterTaskDefinition",
      "ecs:DeregisterTaskDefinition",
    ]

    resources = ["*"]
  }

  statement {
    sid       = "AllowHealthMonitor"
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "elasticloadbalancing:Describe*"
    ]
  }

  #bridgecrew:skip=CKV_AWS_111: Skipping "Write IAM policies without constraints". False positive because the actions are constrained by cluster in the "condition"
  statement {
    sid    = "AllowClusterUpdates"
    effect = "Allow"

    actions = [
      "ecs:DescribeServices",
      "ecs:UpdateService",
      "ecs:*Tasks",
      "ecs:ExecuteCommand",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "ecs:cluster"
      values   = [aws_ecs_cluster.this.arn]
    }
  }
}
