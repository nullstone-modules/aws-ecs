# aws-ecs
Creates an ECS cluster backed by an EC2 auto-scaling group.

## Upgrading nodes with zero downtime

Your apps run in containers ("tasks") spread across EC2 servers ("nodes"). Upgrading a node means
replacing the server underneath your app. Done wrong, the app blinks offline. This module is
configured to do it safely.

### What happens

When you change the node's image (AMI), instance type, or disk size and apply, AWS performs a
**rolling replacement**, one node at a time:

1. Launch a new node with the new settings.
2. Wait for it to be healthy (`warmup_period`, default 5 min).
3. Move tasks off an old node, waiting for each replacement task to come up first.
4. Terminate the empty old node.
5. Repeat until every node is new.

Your app is never below full capacity. You don't run any commands — apply and watch.

### Before you upgrade

Three things stall a rollout. Check them first.

**1. Your app must allow task replacement.** In the app's ECS service, `maximumPercent` must be
above 100 (200 is typical). If `minimumHealthyPercent` and `maximumPercent` are both 100, ECS can
neither start a replacement nor stop an old task, and the upgrade hangs.

**2. You need room for one extra node.** `max_node_count` (default 3) caps the cluster. A rolling
replacement needs to add a node before removing one, so if you're already at the cap, nothing can
launch. Raise it by one for the upgrade if needed.

**3. One-off tasks block their node.** Anything started outside a service (a migration, a script)
is not moved automatically. Its node waits for it to finish. Let those complete before upgrading.

Also worth a look: if your app sits behind a load balancer, its `deregistration_delay` (default
300s) is added to every node's drain time. Lowering it speeds up the rollout.

### Doing the upgrade

The AMI is picked up automatically from AWS's recommended ECS image, so most upgrades are just:

```
tofu apply
```

Watch it in the AWS Console under **EC2 → Auto Scaling Groups → your group → Instance refresh**.
It shows percent complete and which nodes have been replaced. A rollout takes roughly
(number of nodes) × (warmup + drain), so budget ~10 minutes per node.

### If something goes wrong

Cancel from that same Instance refresh screen. Nodes already replaced stay on the new settings;
the rest stay as they are. The cluster keeps serving traffic either way. To go back, revert your
change and apply again.

Two symptoms and their causes:

- **Refresh fails after exactly one hour** — a node couldn't be replaced. Almost always cause #1
  or #2 above.
- **A node sits in `DRAINING` for a long time** — something on it won't stop. Usually cause #3.
  ECS gives up and terminates after 48 hours, so don't wait it out; find the task.

### Notes for maintainers

- The ASG tracks `aws_launch_template.this.latest_version`, not `"$Latest"`. With `"$Latest"` the
  ASG resource never changes, so the instance refresh would never trigger.
- Because the AMI comes from an unpinned SSM lookup, an apply made after AWS publishes a new
  ECS-optimized AMI will roll the nodes. This is intentional (it keeps nodes patched) but means a
  routine apply can start a rollout. Pin `local.ami` if you need applies to be inert.
- `managed_draining = "ENABLED"` on the capacity provider is what makes drains graceful.
  `managed_termination_protection` alone will hard-kill tasks during a refresh.
