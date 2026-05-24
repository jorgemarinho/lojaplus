
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "lojaplus-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "lojaplus-igw"
  }
}

# Discover AZs dynamically and use first two (adjust slice if you want more)
data "aws_availability_zones" "available" {}

locals {
  # Use first 3 AZs for higher availability; change slice length if needed
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
}

# Create public/app/db subnets for each AZ
resource "aws_subnet" "public" {
  count                   = length(local.azs)
  vpc_id                  = aws_vpc.main.id
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 1 + count.index)

  tags = {
    Name = "lojaplus-public-${local.azs[count.index]}"
  }
}

resource "aws_subnet" "app" {
  count             = length(local.azs)
  vpc_id            = aws_vpc.main.id
  availability_zone = local.azs[count.index]
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 11 + count.index)

  tags = {
    Name = "lojaplus-app-${local.azs[count.index]}"
  }
}

resource "aws_subnet" "db" {
  count             = length(local.azs)
  vpc_id            = aws_vpc.main.id
  availability_zone = local.azs[count.index]
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 21 + count.index)

  tags = {
    Name = "lojaplus-db-${local.azs[count.index]}"
  }
}

# Public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "lojaplus-public-rt" }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# NAT Gateways (one per AZ) and EIPs

resource "aws_eip" "nat" {
  count = length(local.azs)
  vpc   = true

  tags = {
    Name = "lojaplus-nat-eip-${local.azs[count.index]}"
  }
}

resource "aws_nat_gateway" "nat" {
  count         = length(local.azs)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "lojaplus-nat-${local.azs[count.index]}"
  }
}

# Private route table per AZ that points to NAT in the same AZ

resource "aws_route_table" "private" {
  count  = length(local.azs)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }

  tags = {
    Name = "lojaplus-private-rt-${local.azs[count.index]}"
  }
}

# Associate app and db subnets to the corresponding private route table (by AZ index)
resource "aws_route_table_association" "app" {
  count          = length(aws_subnet.app)
  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table_association" "db" {
  count          = length(aws_subnet.db)
  subnet_id      = aws_subnet.db[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
