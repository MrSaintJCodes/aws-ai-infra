# gateways.tf

# Internet Gateway — gives public subnet internet access
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "main-igw" }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_eip" "natb" {
  domain = "vpc"
}

# NAT Gateway — lets private subnet reach the internet (outbound only)
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id # NAT lives in the PUBLIC subnet

  tags       = { Name = "main-nat" }
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "natb" {
  allocation_id = aws_eip.natb.id
  subnet_id     = aws_subnet.public_b.id

  tags       = { Name = "main-natb" }
  depends_on = [aws_internet_gateway.igw]
}
