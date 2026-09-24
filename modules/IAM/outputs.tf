# outputs.tf

output "user_names" {
  description = "Names of the IAM users created"
  value       = [for user in aws_iam_user.cob-iamusers : user.name]
}

output "user_arns" {
  description = "ARNs of the IAM users created, keyed by username"
  value       = { for key, user in aws_iam_user.cob-iamusers : key => user.arn }
}

output "group_name" {
  description = "Name of the IAM group created"
  value       = aws_iam_group.cob-group.name
}

output "group_arn" {
  description = "ARN of the IAM group created"
  value       = aws_iam_group.cob-group.arn
}

output "role_arns" {
  description = "ARNs of the IAM roles created, keyed by role name"
  value       = { for key, role in aws_iam_role.cob_iamroles : key => role.arn }
}

output "role_names" {
  description = "Names of the IAM roles created, keyed by role name"
  value       = { for key, role in aws_iam_role.cob_iamroles : key => role.name }
}

output "instance_profile_names" {
  description = "Names of the instance profiles created, keyed by role name"
  value       = { for key, profile in aws_iam_instance_profile.cob_instance_profile : key => profile.name }
}

output "instance_profile_arns" {
  description = "ARNs of the instance profiles created, keyed by role name"
  value       = { for key, profile in aws_iam_instance_profile.cob_instance_profile : key => profile.arn }
}