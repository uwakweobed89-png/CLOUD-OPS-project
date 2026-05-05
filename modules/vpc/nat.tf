# modules/vpc/nat.tf

# ── Elastic IPs ───────────────────────────────────────

resource "aws_eip" "nat_az1" {
    domain = "vpc"
    tags   = { Name = "${var.project_name}-nat-eip-az1" }
}

resource "aws_eip" "nat_az2" {
    domain = "vpc"
    tags   = { Name = "${var.project_name}-nat-eip-az2" }
}

# ── NAT Gateways (placed in PUBLIC subnets) ───────────

resource "aws_nat_gateway" "az1" {
    allocation_id = aws_eip.nat_az1.id
    subnet_id     = aws_subnet.public_az1.id
    tags          = { Name = "${var.project_name}-nat-az1" }
    depends_on    = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "az2" {
    allocation_id = aws_eip.nat_az2.id
    subnet_id     = aws_subnet.public_az2.id
    tags          = { Name = "${var.project_name}-nat-az2" }
    depends_on    = [aws_internet_gateway.main]
}
