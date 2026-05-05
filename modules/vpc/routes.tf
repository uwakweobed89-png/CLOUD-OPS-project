# modules/vpc/routes.tf

# ── PUBLIC route table → IGW ──────────────────────────

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = { Name = "${var.project_name}-public-rt" }
}

resource "aws_route_table_association" "public_az1" {
  subnet_id      = aws_subnet.public_az1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_az2" {
  subnet_id      = aws_subnet.public_az2.id
  route_table_id = aws_route_table.public.id
}

# ── PRIVATE route tables → NAT GW ────────────────────

resource "aws_route_table" "private_az1" {
    vpc_id = aws_vpc.main.id
    route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.az1.id
    }
    tags = { Name = "${var.project_name}-private-rt-az1" }
}

resource "aws_route_table" "private_az2" {
    vpc_id = aws_vpc.main.id
    route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.az2.id
    }
    tags = { Name = "${var.project_name}-private-rt-az2" }
}

resource "aws_route_table_association" "private_az1" {
    subnet_id      = aws_subnet.private_az1.id
    route_table_id = aws_route_table.private_az1.id
}

resource "aws_route_table_association" "private_az2" {
    subnet_id      = aws_subnet.private_az2.id
    route_table_id = aws_route_table.private_az2.id
}
