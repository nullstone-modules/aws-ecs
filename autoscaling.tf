resource "aws_autoscaling_group" "this" {
  max_size = 0
  min_size = 0

  dynamic "tag" {
    for_each = merge(local.tags, { "AmazonECSManaged" = "true" })

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}
