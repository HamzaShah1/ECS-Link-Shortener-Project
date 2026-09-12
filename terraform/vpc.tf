resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet_1" {
  cidr_block        = "10.0.1.0/24"
  vpc_id            = aws_vpc.vpc.id
  availability_zone = "eu-west-2a"

  tags = {
    Name = "public-a"
  }
}

resource "aws_subnet" "subnet_2" {
  cidr_block        = "10.0.2.0/24"
  vpc_id            = aws_vpc.vpc.id
  availability_zone = "eu-west-2a"

  tags = {
    Name = "private-a"
  }
}

resource "aws_subnet" "subnet_3" {
  cidr_block        = "10.0.3.0/24"
  vpc_id            = aws_vpc.vpc.id
  availability_zone = "eu-west-2b"

  tags = {
    Name = "public-b"
  }
}

resource "aws_subnet" "subnet_4" {
  cidr_block        = "10.0.4.0/24"
  vpc_id            = aws_vpc.vpc.id
  availability_zone = "eu-west-2b"

  tags = {
    Name = "private-b"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route" "internet_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "association_subnet_1" {
  subnet_id      = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "association_subnet_3" {
  subnet_id      = aws_subnet.subnet_3.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table_association" "association_subnet_2" {
  subnet_id      = aws_subnet.subnet_2.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "association_subnet_4" {
  subnet_id      = aws_subnet.subnet_4.id
  route_table_id = aws_route_table.private.id
}
