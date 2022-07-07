output "cluster_arn" {
  value       = aws_ecs_cluster.this.arn
  description = "string ||| AWS Arn of the ECS cluster."
}

output "cluster_name" {
  value       = aws_ecs_cluster.this.name
  description = "string ||| Name of the ECS cluster."
}

output "deployers_name" {
  value       = aws_iam_group.deployers.name
  description = "string ||| Name of the deployers IAM Group that is allowed to deploy to the ECS cluster."
}
