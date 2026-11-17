variable "region" {
  description = "AWS region for the state bucket and the fleet."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name, used in resource names and tags."
  type        = string
  default     = "hardened-rhel-fleet"
}

variable "github_owner" {
  description = "GitHub user or organization that owns the repository."
  type        = string
}

variable "github_repo" {
  description = "Repository name, without the owner."
  type        = string
  default     = "hardened-rhel-fleet"
}

variable "create_oidc_provider" {
  description = "Set to false if this AWS account already has the GitHub Actions OIDC provider."
  type        = bool
  default     = true
}
