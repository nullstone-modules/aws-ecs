## 0.2.5 (Jul 09, 2025)
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
