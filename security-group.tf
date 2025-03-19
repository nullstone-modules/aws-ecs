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
