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
  //
  // NOTE: cloud-init runs this script in cloud-final, which has no ordering against docker.service.
  //       On faster instance types dockerd is already running by the time we get here, and mounting
  //       a fresh volume over /var/lib/docker underneath a live dockerd hides its image/overlay state.
  //       ecs.service (After=docker.service, After=cloud-final.service) then fails to start and the node
  //       never joins the cluster. We stop docker first, mount the volume, then start docker + ecs.
  //
  //       ecs.service is PartOf=docker.service, so stopping docker cancels the agent's queued boot-time
  //       start job; we must start it explicitly. It is also ordered After=cloud-final.service, so that
  //       start MUST be --no-block: a blocking start would wait for this very script to finish.
  user_data = <<EOF
#!/bin/bash
set -euo pipefail

# Stop the ECS agent and Docker before repointing Docker's storage directory (see NOTE above).
systemctl stop ecs 2>/dev/null || true
systemctl stop docker docker.socket 2>/dev/null || true

# On Nitro instances the extra EBS volume is presented as an NVMe device; ec2-utils creates the
# /dev/xvdcz symlink once udev settles, which can lag cloud-init. Wait for the device to appear.
DEV=/dev/xvdcz
for _ in $(seq 1 30); do
  if [ -b "$DEV" ]; then break; fi
  sleep 2
done

# Format only when there is no filesystem yet, so reboots and instance replacements never wipe data.
if ! blkid "$DEV" >/dev/null 2>&1; then
  mkfs -t xfs "$DEV"
fi
mkdir -p /var/lib/docker
# "nofail" keeps a missing/renamed disk from blocking boot; mount by the stable /dev/xvdcz symlink.
if ! grep -q /var/lib/docker /etc/fstab; then
  echo "$DEV /var/lib/docker xfs defaults,noatime,nofail 0 2" >> /etc/fstab
fi
mount -a

# Configure the ECS agent, then bring Docker back up on the new storage.
echo ECS_CLUSTER=${aws_ecs_cluster.this.name} >> /etc/ecs/ecs.config
systemctl start docker
# --no-block is required: ecs.service is ordered after cloud-final.service, which is running this script.
systemctl start --no-block ecs
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

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  lifecycle {
    create_before_destroy = true
  }
}
