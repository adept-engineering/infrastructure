resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge({
    Name        = "acqua-vpc-${var.environment}"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
  }, var.tags)
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags = merge({
    Name        = "acqua-public-${count.index}-${var.environment}"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
  }, var.tags)
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = merge({
    Name        = "acqua-private-${count.index}-${var.environment}"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
  }, var.tags)
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = merge({
    Name        = "acqua-igw-${var.environment}"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
  }, var.tags)
}

resource "aws_eip" "nat" {
  vpc = true
  tags = merge({
    Name        = "acqua-nat-eip-${var.environment}"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
  }, var.tags)
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  tags = merge({
    Name        = "acqua-natgw-${var.environment}"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
  }, var.tags)
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags = merge({
    Name        = "acqua-public-rt-${var.environment}"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
  }, var.tags)
}

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  tags = merge({
    Name        = "acqua-private-rt-${var.environment}"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
  }, var.tags)
}

resource "aws_route" "private_nat_gateway" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_db_subnet_group" "this" {
  name       = "acqua-db-subnet-group-${var.environment}"
  subnet_ids = aws_subnet.private[*].id
  tags = merge({
    Name        = "acqua-db-subnet-group-${var.environment}"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
  }, var.tags)
}

data "aws_availability_zones" "available" {} 