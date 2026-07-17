# 0.3.1 (Jul 17, 2026)
* Updated cluster nodes to upgrade with zero downtime.

# 0.3.0 (Jul 17, 2026)
* Upgraded `ns` provider to `0.11.1`.
* Switched to `aws_tags` for proper resource attribution.
* Switched to OpenTofu.

# 0.2.10 (Feb 10, 2026)
* Renamed deployers policy name.

# 0.2.9 (Feb 10, 2026)
* Added `deployers_policy_arn` to outputs.

# 0.2.8 (Feb 10, 2026)
* Added IAM policy for deployers that can be attached to IAM Roles.

# 0.2.7 (Sep 29, 2025)
* Added `var.log_retention_in_days` to dictate log retention on all apps in the cluster.

# 0.2.6 (Jul 10, 2025)
* Added `ecs:TagResource` to deployer policy.

# 0.2.5 (Jul 09, 2025)
* Added `ecs:ListTagsForResource`, `ecs:DescribeTasks` to deployer policy.

# 0.2.4 (Apr 28, 2025)
* Pin AWS provider to 5.95.0. 

# 0.2.3 (Apr 28, 2025)
* Added a secondary storage volume dedicated to Docker. (`var.docker_volume_size`)

# 0.2.2 (Mar 19, 2025)
* Sanitize invalid capacity provider name (i.e. starts with `aws`, `ecs`, or `fargate`).

# 0.2.1 (Mar 19, 2025)
* Sanitize invalid cluster name (i.e. starts with `aws`, `ecs`, or `fargate`).

# 0.2.0 (Mar 19, 2025)
* Upgrade `aws_launch_configuration` to `aws_launch_template`.

# 0.1.0 (Jul 25, 2023)
* Initial release.
