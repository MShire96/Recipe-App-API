output "cd_user_access_key_id" {
  description = "AWS key ID for CD user"
  value       = aws_iam_access_key.cd.id
  # Output of CD user Usernme
}

output "cd_user_access_key_secret" {
  description = "Access key secret for CD user"
  value       = aws_iam_access_key.cd.secret
  sensitive   = true
  # Output of CD user access key password
}

output "ecr_repo_app" {
  description = "ECR repository URL for app image"
  value       = aws_ecr_repository.app.repository_url
  # URL for reposity we create, so build jobs push to the repos
}

output "ecr_repo_proxy" {
  description = "ECR repository URL for proxy image"
  value       = aws_ecr_repository.proxy.repository_url
} 