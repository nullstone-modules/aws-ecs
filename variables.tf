variable "target_capacity" {
  type        = number
  default     = 80
  description = <<EOF
A number from 0 - 100% describing how the cluster should be utilized.
The cluster will automatically add/remove EC2 instances to achieve target capacity.
As an example, a cluster with target capacity of 90 will scale-in/scale-out to have 10% free capacity.
A higher number will reduce resource costs, but slower to respond to demand bursts.
Conversely, a low number will create more EC2 instances, but handle demand bursts rapidly.
See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cluster-auto-scaling.html#target-tracking
EOF

  validation {
    condition     = var.target_capacity >= 1 && var.target_capacity <= 100
    error_message = "Target Capacity must be between 1 and 100."
  }
}

variable "warmup_period" {
  type        = number
  default     = 300
  description = <<EOF
When a cluster creates a new EC2 instance, it takes time to boot before compute resources are stable and ready to run jobs.
The warmup period is the number of seconds to wait before a new EC2 instance in the cluster contributes to scaling metrics.
By default, this is configured to 300 seconds.
EOF
}

variable "min_scaling_step" {
  type        = number
  default     = 1
  description = <<EOF
When the cluster is scaling, min_scaling_step determines the least number of EC2 instances to launch at a time to satisfy demand.
EOF

  validation {
    condition     = var.min_scaling_step >= 1 && var.min_scaling_step <= 10000
    error_message = "Min Scaling Step must be between 1 and 10000."
  }
}

variable "max_scaling_step" {
  type        = number
  default     = 5
  description = <<EOF
When the cluster is scaling, max_scaling_step determines the most number of EC2 instances to launch at a time to satisfy demand.
EOF

  validation {
    condition     = var.max_scaling_step >= 1 && var.max_scaling_step <= 10000
    error_message = "Max Scaling Step must be between 1 and 10000."
  }
}

variable "min_node_count" {
  type        = number
  default     = 0
  description = <<EOF
This places a minimum quota on the number of nodes that the ECS cluster will provision.
If the cluster is idle, AWS will not scale-in below this number of nodes.
See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/asg-capacity-providers.html#asg-capacity-providers-considerations
EOF
}

variable "max_node_count" {
  type        = number
  default     = 3
  description = <<EOF
This places a hard cap on the number of nodes that the ECS cluster will provision.
If the cluster reaches the max node count and new jobs are pending,
they will not leave the PROVISIONING state until this is increased or resources free up.
See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/asg-capacity-providers.html#asg-capacity-providers-considerations
EOF
}

variable "node_instance_type" {
  type        = string
  default     = "m6a.large"
  description = <<EOF
The instance type of the nodes launched with container workloads on them.
See https://aws.amazon.com/ec2/instance-types/ for a list of instance types.
EOF
}

variable "node_volume_size" {
  type        = number
  default     = 30
  description = <<EOF
The number of gigabytes to allocates for the root volume on each node.
EOF
}
