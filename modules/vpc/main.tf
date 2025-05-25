resource "aws_vpc" "three_tier_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name        = "${var.project_name}-VPC"
    Environment = var.project_name
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.three_tier_vpc.id
  tags = {
    Name        = "${var.project_name}-IGW"
    Environment = var.project_name
  }
}

resource "aws_eip" "nat" {
  count  = length(var.public_subnet_cidrs)
  domain = "vpc"
  tags = {
    Name        = "${var.project_name}-NAT-EIP-${count.index + 1}"
    Environment = var.project_name
  }
}

resource "aws_nat_gateway" "this" {
  count         = length(var.public_subnet_cidrs)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  tags = {
    Name        = "${var.project_name}-NAT-GW-${count.index + 1}"
    Environment = var.project_name
  }
  depends_on = [aws_internet_gateway.this]
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.three_tier_vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-Public-${data.aws_availability_zones.available.names[count.index]}"
    Environment = var.project_name
    Tier        = "Public"
  }
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.three_tier_vpc.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "${var.project_name}-Private-${data.aws_availability_zones.available.names[count.index]}"
    Environment = var.project_name
    Tier        = "Private"
  }
}

resource "aws_subnet" "database" {
  count             = length(var.database_subnet_cidrs)
  vpc_id            = aws_vpc.three_tier_vpc.id
  cidr_block        = var.database_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "${var.project_name}-DB-${data.aws_availability_zones.available.names[count.index]}"
    Environment = var.project_name
    Tier        = "Database"
  }
}

resource "aws_route_table" "public" {
  count  = length(var.public_subnet_cidrs)
  vpc_id = aws_vpc.three_tier_vpc.id
  tags = {
    Name        = "${var.project_name}-Public-RT-${count.index + 1}"
    Environment = var.project_name
  }
}

resource "aws_route" "public_internet_access" {
  count                  = length(var.public_subnet_cidrs)
  route_table_id         = aws_route_table.public[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public[count.index].id
}

resource "aws_route_table" "private" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.three_tier_vpc.id
  tags = {
    Name        = "${var.project_name}-Private-RT-${count.index + 1}"
    Environment = var.project_name
  }
}

resource "aws_route" "private_nat_access" {
  count                  = length(var.private_subnet_cidrs)
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.this.*.id, count.index)
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table" "database" {
  count  = length(var.database_subnet_cidrs)
  vpc_id = aws_vpc.three_tier_vpc.id
  tags = {
    Name        = "${var.project_name}-DB-RT-${count.index + 1}"
    Environment = var.project_name
  }
}

resource "aws_route" "database_nat_access" {
  count                  = length(var.database_subnet_cidrs)
  route_table_id         = aws_route_table.database[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.this.*.id, count.index)
}

resource "aws_route_table_association" "database" {
  count          = length(var.database_subnet_cidrs)
  subnet_id      = element(aws_subnet.database.*.id, count.index)
  route_table_id = aws_route_table.database[count.index].id
}

data "aws_availability_zones" "available" {
  state = "available"
}
