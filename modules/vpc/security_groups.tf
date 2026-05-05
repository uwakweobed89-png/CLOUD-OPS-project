# modules/vpc/security_groups.tf

# ── ALB Security Group ────────────────────────────────
resource "aws_security_group" "alb" {
    name        = "${var.project_name}-alb-sg"
    description = "ALB - accepts HTTP/HTTPS from internet"
    vpc_id      = aws_vpc.main.id

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port       = 8080
        to_port         = 8080
        protocol        = "tcp"
        security_groups = [aws_security_group.app.id]
    }

    tags = { Name = "${var.project_name}-alb-sg" }
}

# ── App Security Group ────────────────────────────────
resource "aws_security_group" "app" {
    name        = "${var.project_name}-app-sg"
    description = "App - only accepts traffic from ALB"
    vpc_id      = aws_vpc.main.id

    ingress {
        from_port       = 8080
        to_port         = 8080
        protocol        = "tcp"
        security_groups = [aws_security_group.alb.id]
    }

    egress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port       = 5432
        to_port         = 5432
        protocol        = "tcp"
        security_groups = [aws_security_group.rds.id]
    }

    tags = { Name = "${var.project_name}-app-sg" }
}

# ── RDS Security Group ────────────────────────────────
resource "aws_security_group" "rds" {
    name        = "${var.project_name}-rds-sg"
    description = "RDS - only accepts traffic from App"
    vpc_id      = aws_vpc.main.id

    ingress {
        from_port       = 5432
        to_port         = 5432
        protocol        = "tcp"
        security_groups = [aws_security_group.app.id]
    }

    egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        security_groups = [aws_security_group.app.id]
    }

    tags = { Name = "${var.project_name}-rds-sg" }
}
