locals {
  cluster_name = local.resource_name
}

resource "aws_ecs_cluster" "this" {
  name = local.cluster_name
  tags = local.tags

  // TODO: Enable execute command with encryption configured on logging

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = [aws_ecs_capacity_provider.this.name]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.this.name
  }
}

// https://docs.aws.amazon.com/AmazonECS/latest/developerguide/asg-capacity-providers.html#asg-capacity-providers-considerations
resource "aws_ecs_capacity_provider" "this" {
  name = local.resource_name

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.this.arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      status                 = "ENABLED"
      target_capacity        = var.target_capacity
      instance_warmup_period = var.warmup_period
    }
  }
}
