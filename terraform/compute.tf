locals {
  images = {
    rhel9 = {
      owner = "309956199498" # Red Hat
      name  = "RHEL-9.*_HVM-*-x86_64-*-Hourly2-GP3"
    }
    alma9 = {
      owner = "764336703387" # AlmaLinux OS Foundation
      name  = "AlmaLinux OS 9*x86_64*"
    }
  }
}

data "aws_ami" "os" {
  most_recent = true
  owners      = [local.images[var.os].owner]

  filter {
    name   = "name"
    values = [local.images[var.os].name]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "admin" {
  key_name   = "${var.project}-admin"
  public_key = var.ssh_public_key
}

resource "aws_instance" "fleet" {
  count = var.instance_count

  ami                    = data.aws_ami.os.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.fleet.id
  vpc_security_group_ids = [aws_security_group.fleet.id]
  key_name               = aws_key_pair.admin.key_name
  ebs_optimized          = true

  # IMDSv2 only: blocks the classic metadata-credential theft path.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name = format("%s-%02d", var.project, count.index + 1)
    Role = "fleet"
    OS   = var.os
  }

  lifecycle {
    # A newer AMI should not rebuild running servers on every plan.
    ignore_changes = [ami]
  }
}
