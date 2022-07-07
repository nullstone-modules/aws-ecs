resource "aws_iam_instance_profile" "this" {
  name = local.resource_name
  role = aws_iam_role.this.name
}

resource "aws_iam_role" "this" {
  name               = local.resource_name
  assume_role_policy = data.aws_iam_policy_document.this_assume.json
}

data "aws_iam_policy_document" "this_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

// This policy is necessary for the ECS Agent to connect to the cluster
// See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/instance_IAM_role.html
resource "aws_iam_role_policy_attachment" "container_service" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}
