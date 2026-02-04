# VPC Module
resource "aws_vpc" "three_tier_vpc" {
  cidr_block = var.vpc_ipadr
    tags = {
        Name = "three-tier-vpc"
    }
}

#   internet Gateway
resource "aws_internet_gateway" "vpc_gateway" {
    vpc_id = aws_vpc.three_tier_vpc.id
        tags = {
            Name = "three-tier-igw"
        }
}

#   Public Subnets
resource "aws_subnet" "public_subnets" {
    vpc_id            = aws_vpc.three_tier_vpc.id
    cidr_block        = var.public_sb[count.index]
    availability_zone = var.azs[count.index]
        tags = {
            Name = "public-subnet-${count.index}"
        }
    count = length(var.public_sb)
}

#  Private Subnets
resource "aws_subnet" "private_subnets" {
    vpc_id            = aws_vpc.three_tier_vpc.id
    cidr_block        = var.private_sb[count.index]
    availability_zone = var.azs[count.index]
        tags = {
            Name = "private-subnet-${count.index}"
        }
    count = length(var.private_sb)
}

#   Database Subnets
resource "aws_subnet" "db_subnets" {
    vpc_id            = aws_vpc.three_tier_vpc.id
    cidr_block        = var.db_sb[count.index]
    availability_zone = var.azs[count.index]
        tags = {
            Name = "db-subnet-${count.index}"
        }
    count = length(var.db_sb)
}

# NAT Gateway
resource "aws_eip" "nat_eip" {
    tags = {
        Name = "three-tier-nat-eip"
    }
}

resource "aws_nat_gateway" "threetier_nat" {
    allocation_id = aws_eip.nat_eip.id
    subnet_id     = aws_subnet.public_subnets[0].id
        tags = {
            Name = "three-tier-nat-gateway"
        }
  
}