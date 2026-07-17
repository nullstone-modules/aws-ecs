// https://docs.aws.amazon.com/AmazonECS/latest/developerguide/asg-capacity-providers-create-auto-scaling-group.html#using-warm-pool
resource "aws_autoscaling_group" "this" {
  name                  = local.resource_name
  vpc_zone_identifier   = local.private_subnet_ids
  protect_from_scale_in = true

  // NOTE: The auto-scaling is managed by the ecs capacity provider
  //       max_size puts a hard cap on the ecs capacity provider
  min_size                  = var.min_node_count
  max_size                  = var.max_node_count
  health_check_grace_period = var.warmup_period

  // NOTE: This tracks the launch template version explicitly rather than "$Latest".
  //       "$Latest" never changes this resource, so instance_refresh below would never trigger.
  launch_template {
    id      = aws_launch_template.this.id
    version = aws_launch_template.this.latest_version
  }

  // Roll nodes onto the new launch template (new AMI, instance type, user data) without downtime.
  // https://docs.aws.amazon.com/autoscaling/ec2/userguide/instance-refresh-overview.html
  instance_refresh {
    strategy = "Rolling"

    preferences {
      // The capacity provider protects every instance running tasks from scale-in.
      // Without "Refresh", the refresh waits an hour for protection to clear, then fails.
      // https://docs.aws.amazon.com/AmazonECS/latest/developerguide/managed-instance-draining.html
      scale_in_protected_instances = "Refresh"

      // 100/100 launches a replacement before terminating an old node, so capacity never dips
      // and drained tasks always have somewhere to land.
      min_healthy_percentage = 100
      max_healthy_percentage = 100

      instance_warmup = tostring(var.warmup_period)
    }
  }

  dynamic "tag" {
    for_each = merge(local.tags, { "AmazonECSManaged" = "true" })

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}
// https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-linux.html
// https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html

locals {
  // https://docs.aws.amazon.com/AmazonECS/latest/developerguide/bootstrap_container_instance.html
  // https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-agent-config.html
  user_data = <<EOF
#!/bin/bash

# Format and mount extra disk for Docker usage
mkfs -t xfs /dev/xvdcz
mkdir -p /var/lib/docker
echo '/dev/xvdcz /var/lib/docker xfs defaults,noatime 0 0' >> /etc/fstab
mount -a

# Configure ECS agent
echo ECS_CLUSTER=${aws_ecs_cluster.this.name} >> /etc/ecs/ecs.config
EOF
}

resource "aws_launch_template" "this" {
  name_prefix            = local.block_name
  image_id               = local.ami
  instance_type          = var.node_instance_type
  vpc_security_group_ids = [aws_security_group.this.id]
  user_data              = base64encode(local.user_data)
  tags                   = local.tags

  tag_specifications {
    resource_type = "instance"
    tags          = merge(local.tags, { "Name" = "${local.block_name}/node" })
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.this.name
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_type = "gp3"
      volume_size = var.node_volume_size
    }
  }

  // Additional storage volume dedicated to Docker
  block_device_mappings {
    device_name = "/dev/xvdcz"

    ebs {
      volume_type = "gp3"
      volume_size = var.docker_volume_size
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
