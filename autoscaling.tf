// https://docs.aws.amazon.com/AmazonECS/latest/developerguide/asg-capacity-providers-create-auto-scaling-group.html#using-warm-pool
resource "aws_autoscaling_group" "this" {
  name                  = local.resource_name
  vpc_zone_identifier   = local.private_subnet_ids
  launch_configuration  = aws_launch_configuration.this.name
  protect_from_scale_in = true

  // NOTE: The auto-scaling is managed by the ecs capacity provider
  //       max_size puts a hard cap on the ecs capacity provider
  min_size                  = var.min_node_count
  max_size                  = var.max_node_count
  health_check_grace_period = var.warmup_period

  dynamic "tag" {
    for_each = merge(local.tags, { "AmazonECSManaged" = "true" })

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}
