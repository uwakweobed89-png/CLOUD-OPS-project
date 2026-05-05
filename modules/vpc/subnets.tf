# modules/vpc/subnets.tf

# ── PUBLIC subnets (resources here get a public IP) ──

resource "aws_subnet" "public_az1" {
    vpc_id                  = aws_vpc.main.id
    cidr_block              = "10.0.1.0/24"
    availability_zone       = "${var.aws_region}a"
    map_public_ip_on_launch = true
    tags = { Name = "${var.project_name}-public-az1" }
}

resource "aws_subnet" "public_az2" {
    vpc_id                  = aws_vpc.main.id
    cidr_block              = "10.0.3.0/24"
    availability_zone       = "${var.aws_region}b"
    map_public_ip_on_launch = true
    tags = { Name = "${var.project_name}-public-az2" }
}

# ── PRIVATE subnets (no public IP — isolated) ────────

resource "aws_subnet" "private_az1" {
    vpc_id                  = aws_vpc.main.id
    cidr_block              = "10.0.2.0/24"
    availability_zone       = "${var.aws_region}a"
    map_public_ip_on_launch = false
    tags = { Name = "${var.project_name}-private-az1" }
}

resource "aws_subnet" "private_az2" {
    vpc_id                  = aws_vpc.main.id
    cidr_block              = "10.0.4.0/24"
    availability_zone       = "${var.aws_region}b"
    map_public_ip_on_launch = false
    tags = { Name = "${var.project_name}-private-az2" }
}
