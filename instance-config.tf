// https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-linux.html
// https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html

locals {
  // https://docs.aws.amazon.com/AmazonECS/latest/developerguide/bootstrap_container_instance.html
  // https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-agent-config.html
  user_data = join("\n", [
    "#!/bin/bash",
    "echo ECS_CLUSTER=${aws_ecs_cluster.this.name} >> /etc/ecs/ecs.config",
  ])
}

resource "aws_launch_configuration" "this" {
  name_prefix          = local.resource_name
  image_id             = local.ami
  instance_type        = var.node_instance_type
  security_groups      = [aws_security_group.this.id]
  user_data            = local.user_data
  iam_instance_profile = aws_iam_instance_profile.this.name

  root_block_device {
    volume_type = "gp3"
    volume_size = var.node_volume_size
  }

  // TODO: Mount volume for /dev/xvdcz (docker use) -> this can be used to tune docker image storage
  //       See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/launch_container_instance.html

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "this" {
  name        = local.resource_name
  vpc_id      = local.vpc_id
  description = "Security for each node in ${local.resource_name} ECS cluster"
  tags        = local.tags
}

resource "aws_security_group_rule" "this_to_world4" {
  description       = "Allow each builder node to reach the internet to pull resources over IPv4"
  security_group_id = aws_security_group.this.id
  protocol          = "-1"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "this_to_world6" {
  description       = "Allow each builder node to reach the internet to pull resources over IPv6"
  security_group_id = aws_security_group.this.id
  protocol          = "-1"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  ipv6_cidr_blocks  = ["::/0"]
}
