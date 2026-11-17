output "state_bucket" {
  description = "S3 bucket holding the fleet state. Goes in the TF_STATE_BUCKET repository variable."
  value       = aws_s3_bucket.state.bucket
}

output "plan_role_arn" {
  description = "Goes in the AWS_PLAN_ROLE_ARN repository variable."
  value       = aws_iam_role.plan.arn
}

output "deploy_role_arn" {
  description = "Goes in the AWS_DEPLOY_ROLE_ARN repository variable."
  value       = aws_iam_role.deploy.arn
}

output "region" {
  description = "Goes in the AWS_REGION repository variable."
  value       = var.region
}
