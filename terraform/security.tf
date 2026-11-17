resource "aws_security_group" "fleet" {
  name        = "${var.project}-ssh"
  description = "SSH from the admin address only"
  vpc_id      = aws_vpc.fleet.id

  tags = {
    Name = "${var.project}-ssh"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh_admin" {
  security_group_id = aws_security_group.fleet.id
  description       = "SSH from the admin address"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = var.admin_cidr
}

resource "aws_vpc_security_group_egress_rule" "https_out" {
  security_group_id = aws_security_group.fleet.id
  description       = "HTTPS out for package mirrors"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "http_out" {
  security_group_id = aws_security_group.fleet.id
  description       = "HTTP out for package mirrors that redirect"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "ntp_out" {
  security_group_id = aws_security_group.fleet.id
  description       = "NTP out for chrony"
  ip_protocol       = "udp"
  from_port         = 123
  to_port           = 123
  cidr_ipv4         = "0.0.0.0/0"
}
