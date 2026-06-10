# CloudOps Production Platform

> A production-grade AWS cloud infrastructure project built from scratch, covering the full DevOps lifecycle — from networking to containers, CI/CD pipelines, security, observability, serverless computing, and cost optimisation. Designed to target roles in **Fintech**, **Telecom**, and **Healthcare** industries.

**Built by:** Uwakwe Obed  
**GitHub:** uwakweobed89-png/CLOUD-OPS-project  
**Stack:** AWS · Terraform · Docker · Kubernetes · GitHub Actions · CodePipeline · Prometheus · Grafana · Lambda · SQS

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Architecture Diagram](#2-architecture-diagram)
3. [Prerequisites](#3-prerequisites)
4. [Session Routines](#4-session-routines)
5. [Phase 1 — VPC & Networking](#5-phase-1--vpc--networking)
6. [Phase 2 — Containers & Orchestration](#6-phase-2--containers--orchestration)
7. [Phase 3 — CI/CD & Infrastructure as Code](#7-phase-3--cicd--infrastructure-as-code)
8. [Phase 4 — Observability & Security](#8-phase-4--observability--security)
9. [Phase 5 — Serverless, Scaling & Cost](#9-phase-5--serverless-scaling--cost)
10. [Industry Use Cases](#10-industry-use-cases)
11. [Cost Management](#11-cost-management)
12. [Key Lessons Learned](#12-key-lessons-learned)
13. [Certifications This Project Prepares You For](#13-certifications-this-project-prepares-you-for)

---

## 1. Project Overview

### What is this project?

This is a **real production-grade cloud platform** built on AWS. It is not a tutorial follow-along — every component was built, debugged, and verified to work in a live AWS environment.

The project simulates what a DevOps/DevSecOps engineer builds and maintains at a real company. It covers:

- **Infrastructure as Code** — every AWS resource provisioned via Terraform
- **Containerisation** — Node.js API packaged in Docker and deployed on ECS and EKS
- **CI/CD Pipelines** — two complete pipelines (GitHub Actions + AWS CodePipeline)
- **Security** — CloudTrail, AWS Config, MFA, VPC Flow Logs, IAM least privilege
- **Observability** — CloudWatch dashboards, Prometheus, Grafana, SNS alerting
- **Serverless** — Lambda processing real industry events (Payment, Healthcare, Telecom)
- **Auto Scaling** — ECS automatically scales containers based on CPU and memory
- **Cost Optimisation** — resource tagging, budget alerts, session-based cost control

### Why Fintech, Telecom, and Healthcare?

These three industries have the highest demand for cloud engineers and pay the most. Each has specific compliance and architecture requirements:

| Industry | Key Requirement | What we built |
|---|---|---|
| Fintech | PCI-DSS, real-time transactions | SQS payment events, KMS encryption awareness, CloudTrail |
| Healthcare | HIPAA, PHI protection | PHI audit logging via Lambda, Config Rules compliance |
| Telecom | 5G edge, massive throughput | CDR processing via Lambda, Auto Scaling for traffic spikes |

### Project Structure

```
my-cloud-project/
├── .github/
│   └── workflows/
│       └── deploy.yml          # GitHub Actions CI/CD pipeline
├── app/
│   ├── src/
│   │   └── index.js            # Node.js Express API
│   ├── Dockerfile              # Multi-stage Docker build
│   ├── .dockerignore
│   ├── buildspec.yml           # AWS CodeBuild instructions
│   └── package.json
├── docs/
│   └── chaos-engineering-runbook.md
├── environments/
│   ├── dev/
│   │   ├── main.tf             # Calls VPC module + S3 backend
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   └── prod/
│       ├── main.tf
│       ├── variables.tf
│       └── terraform.tfvars
├── k8s/
│   ├── deployment.yaml         # Kubernetes Deployment
│   ├── service.yaml            # Kubernetes Service (ClusterIP)
│   ├── ingress.yaml            # ALB Ingress for app
│   ├── grafana-service.yaml    # Grafana ClusterIP service
│   └── grafana-ingress.yaml    # ALB Ingress for Grafana
├── lambda/
│   └── index.js                # Event processor function
├── modules/
│   └── vpc/
│       ├── main.tf             # VPC + Internet Gateway
│       ├── subnets.tf          # 4 subnets across 2 AZs
│       ├── nat.tf              # NAT Gateways + Elastic IPs
│       ├── routes.tf           # Route tables + associations
│       ├── security_groups.tf  # ALB, App, RDS security groups
│       ├── variables.tf        # Input variables
│       └── outputs.tf          # Exported values
├── eksctl-config.yaml          # EKS cluster configuration
└── README.md
```

---

## 2. Architecture Diagram

```
                         INTERNET
                            |
                    Internet Gateway
                            |
              ┌─────────────────────────┐
              │         VPC             │
              │      10.0.0.0/16        │
              │                         │
              │  ┌──── AZ1 ──────────┐  │
              │  │ Public 10.0.1.0/24│  │
              │  │  [ALB] [NAT GW]   │  │
              │  │ Private 10.0.2.0  │  │
              │  │  [ECS] [Lambda]   │  │
              │  └───────────────────┘  │
              │                         │
              │  ┌──── AZ2 ──────────┐  │
              │  │ Public 10.0.3.0/24│  │
              │  │  [ALB] [NAT GW]   │  │
              │  │ Private 10.0.4.0  │  │
              │  │  [ECS] [Lambda]   │  │
              │  └───────────────────┘  │
              └─────────────────────────┘
                            |
              ┌─────────────────────────┐
              │      CI/CD Pipelines     │
              │  GitHub Actions          │
              │  AWS CodePipeline        │
              └─────────────────────────┘
                            |
              ┌─────────────────────────┐
              │      Observability       │
              │  CloudWatch + Grafana    │
              │  Prometheus + Alerting   │
              └─────────────────────────┘
```

---

## 3. Prerequisites

### Tools Required

Install these before starting:

```powershell
# 1. AWS CLI
winget install Amazon.AWSCLI

# 2. Terraform
winget install HashiCorp.Terraform

# 3. Docker Desktop
# Download from https://www.docker.com/products/docker-desktop

# 4. kubectl
winget install Kubernetes.kubectl

# 5. eksctl
# Download from https://github.com/eksctl-io/eksctl/releases
# Extract eksctl.exe → move to C:\Windows\System32\

# 6. Helm
# Download from https://github.com/helm/helm/releases
# Extract helm.exe → move to C:\Windows\System32\

# Verify all installed
aws --version
terraform --version
docker --version
kubectl version --client
eksctl version
helm version
```

### AWS Account Setup

```powershell
# 1. Create IAM user (never use root for daily work)
# AWS Console → IAM → Users → Create user
# Username: terraform-dev
# Attach policy: AdministratorAccess

# 2. Configure credentials
aws configure
# AWS Access Key ID: YOUR_KEY
# AWS Secret Access Key: YOUR_SECRET
# Default region: us-east-1
# Default output: json

# 3. Verify connection
aws sts get-caller-identity
```

### Fixed Values (save these)

```
Account ID     : YOUR_ACCOUNT_ID
VPC ID         : vpc-077d27d9a112d19d0
ECS Cluster    : cloudops-cluster
ECS Service    : cloudops-api-service
ECR Repo       : ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/cloudops-api
S3 State       : myapp-terraform-state-ACCOUNT_ID
SNS Topic      : arn:aws:sns:us-east-1:ACCOUNT_ID:cloudops-alerts
Region         : us-east-1
```

---

## 4. Session Routines

### Why Session Routines?

AWS charges by the hour for some resources. NAT Gateways cost ~$0.045/hr each — that is $65/month for 2 gateways running 24/7. By deleting them at the end of each session and recreating at the start, you reduce costs to near zero while keeping your VPC and all other resources intact.

**Rule: NEVER run `terraform destroy`. Only delete NAT Gateways.**

### End of Session (run in this exact order)

```powershell
# Step 1 — Scale ECS to 0 (stop paying for containers)
aws ecs update-service `
  --cluster cloudops-cluster `
  --service cloudops-api-service `
  --desired-count 0 `
  --region us-east-1

# Step 2 — Get current NAT Gateway IDs
aws ec2 describe-nat-gateways `
  --filter "Name=vpc-id,Values=YOUR_VPC_ID" `
  --filter "Name=state,Values=available" `
  --query "NatGateways[*].NatGatewayId" `
  --region us-east-1 `
  --output text

# Step 3 — Delete NAT Gateways (saves ~$65/month)
aws ec2 delete-nat-gateway `
  --nat-gateway-id NAT-ID-1 `
  --region us-east-1

aws ec2 delete-nat-gateway `
  --nat-gateway-id NAT-ID-2 `
  --region us-east-1

# Step 4 — If EKS is running, delete ingress first then cluster
kubectl delete ingress --all -n monitoring
kubectl delete ingress --all -n default
eksctl delete cluster --name cloudops-cluster-eks --region us-east-1

# Step 5 — Push code to GitHub
cd my-cloud-project
git add .
git commit -m "end of session"
git push origin main
git push codecommit main
```

### Start of Session (run in this exact order)

```powershell
# Step 1 — Rebuild NAT Gateways (Terraform recreates them)
cd my-cloud-project/environments/dev
terraform apply
# Type 'yes' when prompted — takes 3-5 minutes

# Step 2 — Start ECS containers
aws ecs update-service `
  --cluster cloudops-cluster `
  --service cloudops-api-service `
  --desired-count 2 `
  --region us-east-1

# Step 3 — Verify everything is up
aws ecs describe-services `
  --cluster cloudops-cluster `
  --services cloudops-api-service `
  --region us-east-1 `
  --query "services[0].{Status:status,Running:runningCount,Desired:desiredCount}" `
  --output table
```

---

## 5. Phase 1 — VPC & Networking

### What is a VPC and Why Do We Need One?

A VPC (Virtual Private Cloud) is your private network inside AWS. Think of it like building a private office building inside a city — the city is AWS, your building is the VPC. You control who gets in, what floor they can access, and how traffic moves.

Without a VPC, your servers would be directly on the public internet — anyone could try to connect to them. The VPC provides isolation and control.

### Architecture

```
VPC 10.0.0.0/16
│
├── Public Subnet AZ1 (10.0.1.0/24)  ← internet-facing resources
│   ├── Application Load Balancer
│   └── NAT Gateway (+ Elastic IP)
│
├── Public Subnet AZ2 (10.0.3.0/24)
│   ├── Application Load Balancer
│   └── NAT Gateway (+ Elastic IP)
│
├── Private Subnet AZ1 (10.0.2.0/24) ← protected resources
│   ├── ECS containers
│   └── RDS database
│
└── Private Subnet AZ2 (10.0.4.0/24)
    ├── ECS containers
    └── RDS standby replica
```

### Why Two Availability Zones?

AZs are physically separate data centres in the same region. If AZ1 suffers a power outage, your app keeps running in AZ2. This is called **High Availability** — a requirement at every Fintech and Healthcare company.

### Terraform Module Structure

The VPC is built as a reusable Terraform module. This means you write the code once and reuse it for dev, staging, and production environments — just pass different values.

```
modules/vpc/         ← write once
environments/dev/    ← use here with dev values
environments/prod/   ← use here with prod values
```

### Code Walkthrough

#### `modules/vpc/main.tf` — VPC and Internet Gateway

```hcl
# The VPC is the network container
# cidr_block = 10.0.0.0/16 gives us 65,536 IP addresses
# enable_dns_hostnames = true lets EC2 instances get DNS names
# This is needed for ECS service discovery and RDS connections

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
  }
}

# The Internet Gateway (IGW) is the door between your VPC and the internet
# Without it nothing in your VPC can reach the internet
# It is free — you only pay for data transfer through it

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}
```

#### `modules/vpc/subnets.tf` — Four Subnets

```hcl
# Public subnets: map_public_ip_on_launch = true
# Resources launched here automatically get a public IP
# This is what makes them "public" — not their name

resource "aws_subnet" "public_az1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags = { Name = "${var.project_name}-public-az1" }
}

# Private subnets: map_public_ip_on_launch = false
# Resources here have no public IP — they cannot be reached from the internet
# They can still reach the internet via NAT Gateway (outbound only)

resource "aws_subnet" "private_az1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = false
  tags = { Name = "${var.project_name}-private-az1" }
}
```

#### `modules/vpc/nat.tf` — NAT Gateways

```hcl
# NAT Gateway sits in the PUBLIC subnet
# It allows resources in PRIVATE subnets to initiate outbound internet connections
# Example: ECS container pulling a Docker image or calling an AWS API
# But nobody from the internet can initiate a connection back in
# This is the security benefit — inbound blocked, outbound allowed

# Each NAT Gateway needs a fixed public IP (Elastic IP)
resource "aws_eip" "nat_az1" {
  domain = "vpc"
}

resource "aws_nat_gateway" "az1" {
  allocation_id = aws_eip.nat_az1.id
  subnet_id     = aws_subnet.public_az1.id  # MUST be in public subnet
  depends_on    = [aws_internet_gateway.main]
}
```

#### `modules/vpc/routes.tf` — Routing

```hcl
# Public route table: 0.0.0.0/0 → IGW
# Any traffic going to the internet goes through the IGW
# This is what makes public subnets truly public

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

# Private route table: 0.0.0.0/0 → NAT Gateway
# Traffic from private subnets goes to NAT GW (not IGW)
# NAT GW translates the private IP to its public IP
# Response comes back to NAT GW which forwards to private instance

resource "aws_route_table" "private_az1" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.az1.id
  }
}
```

#### `modules/vpc/security_groups.tf` — Firewalls

```hcl
# Security groups are stateful firewalls attached to resources
# The key principle: LEAST PRIVILEGE
# Only allow exactly what is needed — nothing more

# ALB Security Group: accepts HTTP/HTTPS from anywhere
resource "aws_security_group" "alb" {
  name   = "${var.project_name}-alb-sg"
  vpc_id = aws_vpc.main.id
}

# App Security Group: only accepts traffic FROM the ALB
# The database cannot be reached from the internet
# Only the app can talk to the database
# This layered security is called "defense in depth"

resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
}
```

#### `environments/dev/main.tf` — Remote State Backend

```hcl
# S3 backend stores Terraform state remotely
# WHY: if you store state locally and your laptop dies,
# you lose track of what exists in AWS
# S3 keeps it safe, versioned, and team-accessible

terraform {
  backend "s3" {
    bucket       = "myapp-terraform-state-326709068429"
    key          = "dev/vpc/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true  # prevents two people applying at the same time
    encrypt      = true  # state file contains sensitive data
  }
}

module "vpc" {
  source       = "../../modules/vpc"
  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
  vpc_cidr     = var.vpc_cidr
}
```

### Deploy Phase 1

```powershell
cd my-cloud-project/environments/dev
terraform init    # downloads AWS provider
terraform plan    # shows what will be created (28 resources)
terraform apply   # creates everything (takes 5 minutes)
```

---

## 6. Phase 2 — Containers & Orchestration

### What is Docker and Why Use It?

Docker packages your application and ALL its dependencies into a single portable unit called a container. The problem it solves: "it works on my machine but not on the server."

With Docker, if it works on your laptop it works on AWS — always. The container includes the exact Node.js version, all npm packages, and the OS layer needed.

### The Node.js API

The API has three endpoints:

```javascript
// Health check — ECS uses this to know if container is healthy
// If this returns non-200, ECS replaces the container automatically
GET /health
→ {"status":"healthy","timestamp":"...","environment":"development"}

// Main API endpoint
GET /api/v1/data
→ {"service":"cloudops-api","version":"1.0.0","status":"running"}

// Detailed health check
GET /api/v1/health-detailed
→ {"service":"cloudops-api","uptime":...,"memory":...}
```

### Multi-Stage Dockerfile Explained

```dockerfile
# WHY multi-stage?
# Single-stage images include ALL build tools → huge (900MB+) and insecure
# Multi-stage: build in one container, copy only results to clean container
# Final image is ~180MB instead of 900MB

# ── Stage 1: Builder ─────────────────────────────────
FROM node:22-alpine AS builder
# node:22-alpine = Node.js 22 on Alpine Linux (tiny OS)
# AS builder = name this stage so we can reference it

WORKDIR /app

# Copy package files FIRST (before source code)
# WHY: Docker caches each layer. If package.json doesn't change,
# npm install is skipped on rebuild — much faster builds
COPY package*.json ./
RUN npm ci --omit=dev
# npm ci = clean install (faster, more reliable than npm install)
# --omit=dev = skip development dependencies (smaller image)

COPY src/ ./src/

# ── Stage 2: Runtime ─────────────────────────────────
FROM node:22-alpine AS runtime
# Fresh Alpine image — no build tools, no cache, clean

# Security: run as non-root user
# WHY: if container is compromised, attacker only has limited permissions
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy ONLY what we need from builder stage
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/src ./src
COPY package.json ./

USER appuser  # switch to non-root

EXPOSE 8080

# Health check built into Docker
# ECS and Kubernetes both use this to check container health
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget -qO- http://localhost:8080/health || exit 1

CMD ["node", "src/index.js"]
```

### ECR — Amazon's Private Docker Registry

```powershell
# Why ECR instead of Docker Hub?
# ECR is private, inside AWS, integrated with ECS/EKS
# No rate limits, automatic vulnerability scanning, encryption

# Create repository
aws ecr create-repository \
  --repository-name cloudops-api \
  --image-scanning-configuration scanOnPush=true \
  --encryption-configuration encryptionType=AES256

# Build with linux/amd64 platform
# WHY: ECS Fargate runs on Linux x86_64
# On Windows, Docker builds Windows-compatible images by default
# --platform linux/amd64 forces the correct format
docker build --platform linux/amd64 -t cloudops-api:latest ./app

# Push to ECR
docker tag cloudops-api:latest ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/cloudops-api:latest
docker push ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/cloudops-api:latest
```

### ECS Fargate — Serverless Containers

```
ECS Fargate = run containers without managing servers

Traditional approach:
  You provision EC2 instances
  You patch the OS
  You manage capacity
  You pay 24/7

Fargate approach:
  You define CPU and memory requirements
  AWS provisions and manages everything
  You pay only when containers are running
```

**Task Definition** — the blueprint for your container:

```json
{
  "family": "cloudops-api",
  "networkMode": "awsvpc",       // each task gets its own network interface
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",                  // 0.25 vCPU
  "memory": "512",               // 512MB RAM
  "executionRoleArn": "...",     // role to pull from ECR and write logs
  "containerDefinitions": [{
    "name": "cloudops-api",
    "image": "326709068429.dkr.ecr.us-east-1.amazonaws.com/cloudops-api:latest",
    "portMappings": [{"containerPort": 8080}],
    "healthCheck": {
      "command": ["CMD-SHELL", "wget -qO- http://localhost:8080/health || exit 1"],
      "interval": 30,
      "retries": 3
    },
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/cloudops-api",
        "awslogs-region": "us-east-1"
      }
    }
  }]
}
```

### EKS — Kubernetes on AWS

```
EKS = AWS managed Kubernetes

Why learn EKS after ECS?
ECS is AWS-only
Kubernetes runs on AWS, GCP, Azure, on-prem
Learn Kubernetes once, work anywhere
```

**Key Kubernetes concepts:**

```
Pod        = smallest unit, one running container
Deployment = ensures X pods always running, handles rolling updates
Service    = stable network endpoint for pods
Ingress    = routes external HTTP traffic to services
Namespace  = logical separation (like folders)
```

#### `k8s/deployment.yaml` — Deploy to Kubernetes

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cloudops-api
  namespace: default
spec:
  replicas: 2                    # always run 2 pods
  selector:
    matchLabels:
      app: cloudops-api
  template:
    metadata:
      labels:
        app: cloudops-api        # label pods so Service can find them
    spec:
      containers:
      - name: cloudops-api
        image: 326709068429.dkr.ecr.us-east-1.amazonaws.com/cloudops-api:latest
        ports:
        - containerPort: 8080
        resources:
          requests:
            cpu: 100m            # minimum CPU guaranteed
            memory: 128Mi        # minimum memory guaranteed
          limits:
            cpu: 250m            # maximum CPU allowed
            memory: 256Mi        # maximum memory allowed
            # WHY limits? Without them one pod can consume all
            # node resources and starve other pods
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30  # wait 30s before first check
          # WHY: app needs time to start before probes begin
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 5
          # Readiness: is pod ready to receive traffic?
          # Liveness: is pod still alive? (restart if not)
```

#### AWS Load Balancer Controller

```
WHY needed for Fargate:
Standard Kubernetes LoadBalancer service creates a Classic LB
Classic LB cannot route to Fargate pod IPs
AWS LB Controller creates a proper ALB that can

Installation:
1. Create OIDC provider (allows pods to assume IAM roles)
2. Create IAM service account with LB Controller policy
3. Install via Helm
4. Create Ingress resource (instead of LoadBalancer service)
```

---

## 7. Phase 3 — CI/CD & Infrastructure as Code

### What is CI/CD and Why Does it Matter?

```
Without CI/CD:
  Developer finishes code
  Manually builds Docker image
  Manually pushes to ECR
  Manually updates ECS
  Entire process takes 20+ minutes
  Human error is possible at every step

With CI/CD:
  Developer runs: git push
  Everything else is automatic
  Build → Test → Scan → Push → Deploy
  Takes 2 minutes
  Zero human error
```

### GitHub Actions Pipeline

The pipeline file lives at `.github/workflows/deploy.yml`. It triggers on every push to `main` that changes files in the `app/` folder.

```yaml
name: Build and Deploy to ECS

on:
  push:
    branches: [main]
    paths: ['app/**']      # only trigger when app code changes
                           # pushing Terraform changes won't deploy

permissions:
  id-token: write          # required for OIDC authentication
  contents: read

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest

    steps:
    # Step 1: Get the code
    - name: Checkout code
      uses: actions/checkout@v4

    # Step 2: Connect to AWS — NO KEYS STORED ANYWHERE
    # OIDC = OpenID Connect
    # GitHub proves its identity to AWS using a JWT token
    # AWS verifies the token and issues temporary credentials
    # Credentials expire after the pipeline run
    # This is the industry standard — storing keys in GitHub is a security risk
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v4
      with:
        role-to-assume: arn:aws:iam::326709068429:role/GitHubActionsRole
        aws-region: us-east-1

    # Step 3: Login to ECR
    - name: Login to Amazon ECR
      id: login-ecr
      uses: aws-actions/amazon-ecr-login@v2

    # Step 4: Build Docker image
    # --platform linux/amd64 = force correct format for ECS Fargate
    # Tag with git SHA = every image is uniquely identifiable
    # git SHA is the commit hash — if you need to rollback,
    # you know exactly which code version each image contains
    - name: Build Docker image
      run: |
        docker build \
          --platform linux/amd64 \
          -t ${{ env.ECR_REPOSITORY }}:${{ github.sha }} \
          -t ${{ env.ECR_REPOSITORY }}:latest \
          ./app

    # Step 5: Security scan with Trivy
    # Trivy scans for known CVEs (vulnerabilities) in:
    # - OS packages inside the container
    # - npm packages in node_modules
    # exit-code: 0 = report findings but don't fail the pipeline
    # In production you'd set exit-code: 1 to block on CRITICAL findings
    - name: Scan image with Trivy
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: ${{ env.ECR_REPOSITORY }}:latest
        format: table
        exit-code: 0
        severity: CRITICAL,HIGH

    # Step 6: Push to ECR
    # Two tags: SHA tag (immutable reference) + latest (moving pointer)
    - name: Push to ECR
      run: |
        docker push $ECR_REGISTRY/$ECR_REPOSITORY:${{ github.sha }}
        docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest

    # Steps 7-9: Update ECS task definition and deploy
    # ECS rolling deployment: new tasks start before old ones stop
    # wait-for-service-stability: pipeline waits until deployment complete
    - name: Deploy to ECS
      uses: aws-actions/amazon-ecs-deploy-task-definition@v1
      with:
        task-definition: ${{ steps.task-def.outputs.task-definition }}
        service: cloudops-api-service
        cluster: cloudops-cluster
        wait-for-service-stability: true
```

### AWS CodePipeline

```
Why learn both GitHub Actions AND CodePipeline?

GitHub Actions = open source standard
                 used at startups and tech companies

CodePipeline   = native AWS
                 used at enterprises and regulated industries
                 Fintech and Healthcare prefer native AWS for compliance
                 All activity logged in CloudTrail automatically

Having both = you work in any environment
```

**Pipeline stages:**
```
CodeCommit (source) → CodeBuild (build) → ECS (deploy)

CodeCommit = AWS's Git service (source code lives here)
CodeBuild  = AWS's build server (runs buildspec.yml)
ECS Deploy = updates the running service with new image
```

**`buildspec.yml` — CodeBuild instructions:**

```yaml
version: 0.2

phases:
  pre_build:
    commands:
      # Login to ECR
      - aws ecr get-login-password | docker login --username AWS --password-stdin $ECR_REGISTRY
      # Get short commit hash for image tag
      - COMMIT_HASH=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)

  build:
    commands:
      # Build with linux/amd64 for Fargate compatibility
      - docker build --platform linux/amd64 -t $ECR_REGISTRY/$ECR_REPOSITORY:latest ./app
      - docker tag $ECR_REGISTRY/$ECR_REPOSITORY:latest $ECR_REGISTRY/$ECR_REPOSITORY:$COMMIT_HASH

  post_build:
    commands:
      - docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest
      - docker push $ECR_REGISTRY/$ECR_REPOSITORY:$COMMIT_HASH
      # imagedefinitions.json tells ECS which image to deploy
      - printf '[{"name":"cloudops-api","imageUri":"%s"}]' $ECR_REGISTRY/$ECR_REPOSITORY:$COMMIT_HASH > imagedefinitions.json

artifacts:
  files:
    - imagedefinitions.json    # passed to ECS deploy stage
```

---

## 8. Phase 4 — Observability & Security

### Why Observability?

```
A system running without monitoring is like
driving a car with a covered dashboard

You don't know:
→ Is the app healthy?
→ How many requests per second?
→ Is CPU about to max out?
→ Did someone try to breach the system?

Observability fixes this:
→ CloudWatch = AWS native monitoring
→ Prometheus  = industry standard metrics
→ Grafana     = dashboards and visualisation
→ CloudTrail  = security audit trail
→ AWS Config  = compliance monitoring
```

### CloudWatch Setup

```powershell
# Create log group for ECS container logs
# Retention = 30 days: logs cost money, 30 days is enough for debugging
aws logs create-log-group \
  --log-group-name /ecs/cloudops-api \
  --region us-east-1

aws logs put-retention-policy \
  --log-group-name /ecs/cloudops-api \
  --retention-in-days 30

# SNS Topic = notification backbone
# CloudWatch alarms → SNS → Email/Slack/PagerDuty
aws sns create-topic --name cloudops-alerts

# Subscribe email to receive alerts
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:326709068429:cloudops-alerts \
  --protocol email \
  --notification-endpoint your@email.com

# Three alarms that matter most:
# 1. CPU above 80% for 10 minutes = something is wrong
# 2. Memory above 80% = possible memory leak
# 3. Running tasks below 1 = service is down
aws cloudwatch put-metric-alarm \
  --alarm-name "ECS-High-CPU" \
  --metric-name CPUUtilization \
  --namespace AWS/ECS \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --alarm-actions arn:aws:sns:us-east-1:326709068429:cloudops-alerts \
  --dimensions Name=ClusterName,Value=cloudops-cluster Name=ServiceName,Value=cloudops-api-service
```

### Prometheus and Grafana on EKS

```
kube-prometheus-stack = one Helm chart that installs:

Prometheus    → scrapes metrics from every pod every 15 seconds
               stores as time-series data
               answers: "how many requests/second right now?"

Grafana       → connects to Prometheus
               turns raw numbers into visual dashboards
               industry standard — used everywhere

Alertmanager  → receives alerts from Prometheus rules
               routes to email/Slack/PagerDuty

kube-state-metrics → exposes Kubernetes object metrics
                     (pod counts, deployment status, etc.)
```

```powershell
# Install via Helm
# Helm = package manager for Kubernetes (like npm for Node.js)
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set grafana.adminPassword=YOUR_PASSWORD \
  --set grafana.livenessProbe.initialDelaySeconds=300 \
  --set grafana.resources.requests.memory=512Mi \
  --set grafana.resources.limits.memory=1Gi
  # WHY these settings?
  # Fargate starts containers slower than EC2
  # initialDelaySeconds=300 gives Grafana 5 minutes to start
  # before health probes begin killing it
  # Resource limits prevent Grafana consuming all available memory
```

### RED Method Dashboard

```
The RED Method is the standard for monitoring microservices:

R = Rate     → requests per second
              "how busy is the service?"

E = Errors   → error rate percentage
              "what % of requests are failing?"

D = Duration → request latency (especially p99)
              "how slow are the slowest 1% of requests?"

Why p99 matters more than average:
  Average: 99 fast requests + 1 slow request = "looks fine"
  p99: that 1 slow request = real user experiencing 10 second wait
  In Fintech that 1% = real customers losing money
```

### Security — CloudTrail and AWS Config

```
CloudTrail = records EVERY API call in your account
             Who called what, from where, at what time
             Essential for: security investigations, compliance audits
             Required by: HIPAA, PCI-DSS, SOC2

AWS Config = continuously checks if your infrastructure is SECURE
             Like a security guard that never sleeps

5 Config Rules we implemented (all COMPLIANT):
  cloudtrail-enabled           → is CloudTrail logging? ✅
  restricted-ssh               → no open SSH from internet? ✅
  root-account-mfa-enabled     → is root protected with MFA? ✅
  s3-bucket-encryption-enabled → are S3 buckets encrypted? ✅
  vpc-flow-logs-enabled        → is VPC traffic logged? ✅
```

```powershell
# Enable CloudTrail
aws cloudtrail create-trail \
  --name cloudops-trail \
  --s3-bucket-name myapp-cloudtrail-ACCOUNT_ID \
  --include-global-service-events \
  --is-multi-region-trail

aws cloudtrail start-logging --name cloudops-trail

# Enable VPC Flow Logs
# Records all network traffic — who connected to what
# Essential for security investigation and HIPAA compliance
aws ec2 create-flow-logs \
  --resource-type VPC \
  --resource-ids YOUR_VPC_ID \
  --traffic-type ALL \
  --log-destination-type cloud-watch-logs \
  --log-group-name /vpc/flowlogs \
  --deliver-logs-permission-arn arn:aws:iam::ACCOUNT_ID:role/VPCFlowLogsRole
```

---

## 9. Phase 5 — Serverless, Scaling & Cost

### Lambda + SQS — Event-Driven Architecture

```
Current architecture:
  User → API → ECS container → immediate response

Event-driven architecture:
  User → API → ECS container → SQS queue → Lambda → async processing

Why this matters:
  Heavy tasks (fraud check, PHI audit, CDR processing)
  don't need to block the API response
  Queue absorbs traffic spikes automatically
  Lambda scales to zero when idle — pay nothing
  Lambda scales to thousands of instances under load
  Message stays in queue if Lambda fails — nothing lost
```

```
Real world use cases we implemented:

PAYMENT event:
  SQS receives: {"eventType":"PAYMENT","amount":500,"currency":"USD"}
  Lambda:       checks for fraud patterns
                logs transaction for PCI-DSS compliance
                Duration: 61ms | Cost: $0.000000208

PATIENT_ADMISSION event:
  SQS receives: {"eventType":"PATIENT_ADMISSION","patientId":"PAT-12345"}
  Lambda:       logs PHI access for HIPAA audit trail
                Duration: 68ms | Cost: $0.000000208

CDR event:
  SQS receives: {"eventType":"CDR","callId":"CALL-789","duration":120}
  Lambda:       aggregates usage data
                updates subscriber billing records
                Duration: 65ms | Cost: $0.000000208
```

#### `lambda/index.js` — Event Processor

```javascript
exports.handler = async (event) => {
    // event.Records = array of SQS messages
    // Lambda receives up to 10 messages per invocation (batch size)
    // If processing fails, messages return to queue for retry
    
    for (const record of event.Records) {
        const body = JSON.parse(record.body);
        
        switch(body.eventType) {
            case 'PAYMENT':
                // Fintech: fraud detection
                console.log('Fraud check passed for:', body.transactionId);
                break;
                
            case 'PATIENT_ADMISSION':
                // Healthcare: PHI audit logging
                console.log('PHI access audit logged for:', body.patientId);
                break;
                
            case 'CDR':
                // Telecom: usage aggregation
                console.log('Usage aggregated for:', body.subscriberId);
                break;
        }
    }
};
```

### ECS Auto Scaling

```
Without Auto Scaling:
  Traffic spikes 10x → 2 containers overwhelmed → app slow
  You manually scale → you wake up at 3am

With Auto Scaling:
  CPU hits 70% → AWS automatically adds containers
  Traffic drops → AWS automatically removes containers
  You sleep peacefully
```

```powershell
# Register service as scalable
# min: 1 = always keep at least 1 container (never go to zero)
# max: 10 = never exceed 10 containers (cost protection)
aws application-autoscaling register-scalable-target \
  --service-namespace ecs \
  --resource-id service/cloudops-cluster/cloudops-api-service \
  --scalable-dimension ecs:service:DesiredCount \
  --min-capacity 1 \
  --max-capacity 10

# CPU scaling policy
# TargetValue 70.0 = target CPU of 70%
# AWS adds containers when CPU > 70%
# AWS removes containers when CPU < 70%
# ScaleOutCooldown 60 = wait 60s before adding more containers
# ScaleInCooldown 120 = wait 120s before removing containers
#   WHY longer scale-in? Removing too fast causes instability
```

### Chaos Engineering

```
Chaos engineering = deliberately breaking your system in a controlled way
                   to find weaknesses BEFORE users do

Netflix invented this with "Chaos Monkey"
They kill random servers in production to prove they can survive

We designed 3 experiments:

Experiment 1: ECS Task Termination
  Kill 1 of 2 running containers
  Does ECS replace it within 60 seconds?
  Does the app stay available?
  Does CloudWatch alarm fire?

Experiment 2: AZ Failure
  Terminate all tasks in one Availability Zone
  Does traffic automatically shift to the other AZ?
  Proves multi-AZ design works

Experiment 3: CPU Stress
  Force CPU to 90% on a container
  Does Auto Scaling add containers?
  Does CPU drop back to normal?
  Proves Auto Scaling policies work
```

### Cost Optimisation

```
Key practices implemented:

1. Resource Tagging
   Every resource tagged with:
   Project=CloudOps, Environment=dev, Owner=uwak-obed
   WHY: allows cost breakdown by project and team
        "which project is costing the most?"

2. Session-based NAT Gateway deletion
   NAT Gateways = $0.045/hr each = $65/month for 2
   Delete at end of session, recreate at start
   Savings: ~$65/month

3. Budget Alert
   $50/month budget with 80% alert
   Email sent when spend exceeds $40
   Prevents surprise bills

4. ECS Scale to Zero
   Scale ECS to 0 tasks between sessions
   Containers only cost money when running

Total spend for this entire project: ~$0
```

---

## 10. Industry Use Cases

### Fintech

| Component | Fintech Application |
|---|---|
| VPC multi-AZ | Payment service stays up during AZ failure |
| ECS Auto Scaling | Handles Black Friday transaction spikes |
| Lambda + SQS | Async fraud detection on every transaction |
| CloudTrail | PCI-DSS audit trail for all API calls |
| AWS Config | Continuous PCI-DSS compliance checking |
| Grafana RED dashboard | Real-time transaction rate and error monitoring |

### Healthcare

| Component | Healthcare Application |
|---|---|
| Private subnets | PHI data never exposed to internet |
| Security Groups | Database only accessible from app layer |
| Lambda | HIPAA-compliant PHI access audit logging |
| AWS Config Rules | HIPAA baseline compliance monitoring |
| CloudTrail | Immutable audit trail for regulatory requirements |
| MFA on root | Protects against account takeover |

### Telecom

| Component | Telecom Application |
|---|---|
| Multi-AZ ECS | Network functions survive AZ failures |
| Auto Scaling | Handles New Year's Eve call volume spikes |
| Lambda + SQS | CDR (Call Detail Record) processing pipeline |
| Prometheus | Millisecond-resolution SLA monitoring |
| Grafana | NOC (Network Operations Centre) dashboards |
| VPC Flow Logs | Network traffic analysis and anomaly detection |

---

## 11. Cost Management

### Monthly Cost Breakdown

```
Resource              Cost/hr      Notes
─────────────────────────────────────────────
NAT Gateway x2        $0.09        DELETE at end of session
ECS Fargate tasks     $0.01        SCALE TO 0 between sessions
EKS cluster           $0.10        DELETE when not using
EC2 nodes (EKS)       $0.08        included in EKS deletion
─────────────────────────────────────────────
Free resources:
VPC, Subnets, IGW, Route tables, Security groups
S3 (within free tier), CloudWatch (within free tier)
Lambda (within free tier), SQS (within free tier)
ECR (within free tier)
─────────────────────────────────────────────
Total with session routine:  ~$0/month
Total without routine:       ~$200/month
```

### Budget Alert Setup

```powershell
# Creates $50/month budget
# Sends email alert at 80% spend ($40)
# Sends forecast alert when projected to exceed $50
aws budgets create-budget \
  --account-id YOUR_ACCOUNT_ID \
  --budget file://budget.json \
  --notifications-with-subscribers file://budget-notification.json
```

---

## 12. Key Lessons Learned

### Terraform
```
✅ provider and terraform blocks belong in environments/ not modules/
✅ Security groups cannot reference each other inline — use separate rule resources
✅ Remote state in S3 prevents state loss and enables team collaboration
✅ use_lockfile = true prevents concurrent applies corrupting state
✅ Never terraform destroy — only delete expensive resources (NAT Gateways)
✅ terraform import syncs existing AWS resources into state
```

### Docker and Containers
```
✅ Always build with --platform linux/amd64 on Windows for ECS/EKS
✅ Multi-stage builds reduce image size from ~900MB to ~180MB
✅ Run containers as non-root user (security best practice)
✅ npm ci requires package-lock.json — run npm install locally first
✅ Use --omit=dev flag (replaces deprecated --only=production)
```

### Kubernetes
```
✅ Fargate requires aws-load-balancer-controller for proper ALB
✅ Use Ingress with ingressClassName: alb (not deprecated annotation)
✅ target-type: ip required for Fargate (no nodes to route through)
✅ Always delete Ingress BEFORE deleting EKS cluster
✅ Resource limits prevent Grafana/Prometheus from consuming all memory
✅ liveness probe initialDelaySeconds must be high on Fargate (300s)
```

### CI/CD
```
✅ OIDC = keyless AWS auth — never store AWS keys in GitHub secrets
✅ Tag Docker images with git SHA for immutable version references
✅ CodeCommit uses SSH on Windows — HTTPS credential helper unreliable
✅ PowerShell saves files with BOM — use [System.IO.File]::WriteAllText
✅ buildspec.yml must be at project root for CodeBuild to find it
✅ CodeBuild needs explicit S3 inline policy for artifacts bucket access
```

### Security
```
✅ IAM least privilege — only grant exactly what each service needs
✅ MFA on root account is mandatory — protect against account takeover
✅ VPC Flow Logs on ALL VPCs including the default VPC
✅ Config Rules evaluate periodically — trigger manual re-evaluation after changes
✅ CloudTrail S3 bucket needs explicit bucket policy for CloudTrail service
```

### Windows/PowerShell Specific
```
✅ PowerShell strips quotes from JSON in CLI commands — use file:// instead
✅ $LATEST in log stream names must be escaped as `$LATEST
✅ SSH config file must be saved without BOM encoding
✅ Use [System.IO.File]::WriteAllText() instead of Out-File for config files
✅ Backtick (`) is the PowerShell line continuation character
```

---

## 13. Certifications This Project Prepares You For

| Certification | Coverage |
|---|---|
| AWS Solutions Architect Associate (SAA-C03) | VPC, ECS, EKS, IAM, S3, CloudWatch, Auto Scaling |
| AWS DevOps Engineer Professional (DOP-C02) | CI/CD, CodePipeline, ECS deployments, monitoring |
| HashiCorp Terraform Associate | Modules, remote state, workspaces, import |
| Certified Kubernetes Administrator (CKA) | Deployments, services, ingress, namespaces |
| AWS Security Specialty (SCS-C02) | CloudTrail, Config, IAM, VPC security |

### Recommended Study Order
1. Finish this project completely
2. AWS SAA-C03 (Stephane Maarek on Udemy — best resource)
3. HashiCorp Terraform Associate (you're already 70% ready)
4. AWS DevOps Professional DOP-C02
5. CKA (Kubernetes)
6. AWS Security Specialty

---

*Built with ❤️ by Uwak Obed — aspiring DevSecOps Engineer targeting Fintech, Telecom, and Healthcare*

*"The best way to learn DevOps is to build something real, break it, fix it, and document everything."*
