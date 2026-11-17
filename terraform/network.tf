resource "aws_vpc" "fleet" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project}-vpc"
  }
}

resource "aws_internet_gateway" "fleet" {
  vpc_id = aws_vpc.fleet.id

  tags = {
    Name = "${var.project}-igw"
  }
}

resource "aws_subnet" "fleet" {
  vpc_id                  = aws_vpc.fleet.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project}-subnet"
  }
}

resource "aws_route_table" "fleet" {
  vpc_id = aws_vpc.fleet.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.fleet.id
  }

  tags = {
    Name = "${var.project}-rt"
  }
}

resource "aws_route_table_association" "fleet" {
  subnet_id      = aws_subnet.fleet.id
  route_table_id = aws_route_table.fleet.id
}

# The VPC's default security group is left with no rules, so nothing can use it by accident.
resource "aws_default_security_group" "locked" {
  vpc_id = aws_vpc.fleet.id

  tags = {
    Name = "${var.project}-default-locked"
  }
}
