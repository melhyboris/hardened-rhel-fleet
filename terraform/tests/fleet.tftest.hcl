# Runs with `terraform test`. The AWS provider is mocked, so these tests need
# no credentials and create nothing; they check the plan's logic in CI.

mock_provider "aws" {
  mock_data "aws_ami" {
    defaults = {
      id   = "ami-0123456789abcdef0"
      name = "RHEL-9.4.0_HVM-20240605-x86_64-82-Hourly2-GP3"
    }
  }
}

variables {
  admin_cidr     = "203.0.113.10/32"
  ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExampleKeyForTestsOnly000000000000000000000 test@example"
}

run "builds_three_tagged_servers" {
  command = plan

  assert {
    condition     = length(aws_instance.fleet) == 3
    error_message = "The fleet should have three servers by default."
  }

  assert {
    condition     = alltrue([for i in aws_instance.fleet : i.tags["Role"] == "fleet"])
    error_message = "Every server needs the Role=fleet tag the Ansible inventory groups on."
  }

  assert {
    condition     = aws_instance.fleet[0].tags["Name"] == "hardened-rhel-fleet-01"
    error_message = "Server names should be numbered from 01."
  }
}

run "servers_are_locked_down_at_the_cloud_layer" {
  command = plan

  assert {
    condition     = alltrue([for i in aws_instance.fleet : i.metadata_options[0].http_tokens == "required"])
    error_message = "IMDSv2 must be required on every server."
  }

  assert {
    condition     = alltrue([for i in aws_instance.fleet : i.root_block_device[0].encrypted])
    error_message = "Root volumes must be encrypted."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.ssh_admin.from_port == 22 && aws_vpc_security_group_ingress_rule.ssh_admin.to_port == 22
    error_message = "The only inbound rule should be SSH."
  }

  assert {
    condition     = nonsensitive(aws_vpc_security_group_ingress_rule.ssh_admin.cidr_ipv4) == "203.0.113.10/32"
    error_message = "SSH must be limited to the admin address."
  }
}

run "refuses_ssh_open_to_the_world" {
  command = plan

  variables {
    admin_cidr = "0.0.0.0/0"
  }

  expect_failures = [var.admin_cidr]
}

run "refuses_an_unknown_operating_system" {
  command = plan

  variables {
    os = "windows"
  }

  expect_failures = [var.os]
}
