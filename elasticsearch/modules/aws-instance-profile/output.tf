output "ec2-instance-profile-name" {
  value = aws_iam_instance_profile.this.name
}

output "ec2-iam-role-name" {
  value = aws_iam_role.role.name
}

output "ec2-iam-role-arn" {
  value = aws_iam_role.role.arn
}