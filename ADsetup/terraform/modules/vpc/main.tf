resource "aws_vpc" "ad" {
  cidr_block = "172.241.0.0/16"

  tags = {
    Name = "A/D Game VPC"
  }
}

resource "aws_subnet" "main" {
  vpc_id            = aws_vpc.ad.id
  cidr_block        = "172.241.0.0/16"
  availability_zone = "eu-west-1a" # change this : if you have a different zone on aws

  tags = {
    Name = "Public subnet"
  }
}

resource "aws_internet_gateway" "ad" {
  vpc_id = aws_vpc.ad.id

  tags = {
    Name = "Vulnbox Internet Gateway"
  }
}

# Public Route Table (Subnets with IGW)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.ad.id
}

# Public Route
resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ad.id
}

# Public Route to Public Route Table for Public Subnets
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.public.id
}

