
# modules/vpc/security_groups.tf

# ── Create the 3 empty Security Groups first ──────────
# Note: We create the SGs first without rules to avoid circular dependencies, 
# since the rules reference each other.

resource "aws_security_group" "alb" {
    name        = "${var.project_name}-alb-sg"
    description = "ALB security group"
    vpc_id      = aws_vpc.main.id
    tags        = { Name = "${var.project_name}-alb-sg" }
}

resource "aws_security_group" "app" {
    name        = "${var.project_name}-app-sg"
    description = "App security group"
    vpc_id      = aws_vpc.main.id
    tags        = { Name = "${var.project_name}-app-sg" }
}

resource "aws_security_group" "rds" {
    name        = "${var.project_name}-rds-sg"
    description = "RDS security group"
    vpc_id      = aws_vpc.main.id
    tags        = { Name = "${var.project_name}-rds-sg" }
}

# ── ALB rules ─────────────────────────────────────────
# Note: The ALB SG needs to allow incoming traffic from the Internet on ports 80 and 443, 
# and outgoing traffic to the App SG on port 8080.

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
    security_group_id = aws_security_group.alb.id
    cidr_ipv4         = "0.0.0.0/0"
    from_port         = 80
    to_port           = 80
    ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
    security_group_id = aws_security_group.alb.id
    cidr_ipv4         = "0.0.0.0/0"
    from_port         = 443 
    to_port           = 443
    ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_app" {
    security_group_id            = aws_security_group.alb.id
    referenced_security_group_id = aws_security_group.app.id
    from_port                    = 8080
    to_port                      = 8080
    ip_protocol                  = "tcp"
}

# ── App rules ─────────────────────────────────────────
# Note: The App SG needs to allow incoming traffic from the ALB SG on port 8080, 
# and outgoing traffic to the RDS SG on port 5432.

resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
    security_group_id            = aws_security_group.app.id
    referenced_security_group_id = aws_security_group.alb.id
    from_port                    = 8080
    to_port                      = 8080
    ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "app_to_rds" {
    security_group_id            = aws_security_group.app.id
    referenced_security_group_id = aws_security_group.rds.id
    from_port                    = 5432
    to_port                      = 5432
    ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "app_to_internet" {
    security_group_id = aws_security_group.app.id
    cidr_ipv4         = "0.0.0.0/0"
    from_port         = 443
    to_port           = 443
    ip_protocol       = "tcp"
}

# ── RDS rules ─────────────────────────────────────────
# Note: RDS doesn't need an egress rule to the Internet 
# because it won't initiate outbound connections. It only needs to allow incoming connections from the App SG.

resource "aws_vpc_security_group_ingress_rule" "rds_from_app" {
    security_group_id            = aws_security_group.rds.id
    referenced_security_group_id = aws_security_group.app.id
    from_port                    = 5432
    to_port                      = 5432
    ip_protocol                  = "tcp"
}

# Note: RDS doesn't need an egress rule to the Internet because it won't initiate outbound connections. 
# However, we can add an egress rule to allow it to communicate with the App SG
# if needed (e.g., for monitoring or backups). This is optional and can be omitted if you want to be more restrictive.
resource "aws_vpc_security_group_egress_rule" "rds_to_app" {
    security_group_id            = aws_security_group.rds.id
    referenced_security_group_id = aws_security_group.app.id
    ip_protocol                  = "-1"
}
