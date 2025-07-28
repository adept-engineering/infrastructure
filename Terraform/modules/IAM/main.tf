resource "aws_iam_role" "ec2_role" {
  name = "acqua-ec2-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags = merge({
    Name        = "acqua-ec2-role-${var.environment}"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
  }, var.tags)
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "acqua-ec2-profile-${var.environment}"
  role = aws_iam_role.ec2_role.name
  tags = merge({
    Name        = "acqua-ec2-profile-${var.environment}"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
  }, var.tags)
}

resource "aws_iam_role_policy_attachment" "ec2_role_policies" {
  count      = length(var.ec2_policy_arns)
  role       = aws_iam_role.ec2_role.name
  policy_arn = var.ec2_policy_arns[count.index]
} 