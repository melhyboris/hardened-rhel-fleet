variable "region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name, used in resource names and tags. The Ansible inventory filters on this tag."
  type        = string
  default     = "hardened-rhel-fleet"
}

variable "admin_cidr" {
  description = "The only address allowed to reach SSH, as a /32. Example: 203.0.113.10/32."
  type        = string
  sensitive   = true

  validation {
    condition     = can(cidrhost(var.admin_cidr, 0)) && !startswith(var.admin_cidr, "0.0.0.0")
    error_message = "admin_cidr must be a valid CIDR and must not be open to the world."
  }
}

variable "ssh_public_key" {
  description = "Public half of the SSH key Ansible connects with (contents of the .pub file)."
  type        = string

  validation {
    condition     = can(regex("^(ssh-ed25519|ssh-rsa|ecdsa-sha2-)", var.ssh_public_key))
    error_message = "ssh_public_key must be an OpenSSH public key."
  }
}

variable "os" {
  description = "Operating system image: rhel9 (Red Hat, adds a per-hour license fee) or alma9 (AlmaLinux, no license fee)."
  type        = string
  default     = "rhel9"

  validation {
    condition     = contains(["rhel9", "alma9"], var.os)
    error_message = "os must be rhel9 or alma9."
  }
}

variable "instance_count" {
  description = "Number of servers in the fleet."
  type        = number
  default     = 3

  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 6
    error_message = "instance_count must be between 1 and 6."
  }
}

variable "instance_type" {
  description = "Instance type. An OpenSCAP scan needs about 2 GB of RAM, so t3.small is the practical minimum."
  type        = string
  default     = "t3.small"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.10.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the fleet subnet."
  type        = string
  default     = "10.10.1.0/24"
}
