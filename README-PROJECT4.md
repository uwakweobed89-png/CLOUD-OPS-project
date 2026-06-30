# Project 4 — Multi-Tier Architecture + GitOps Deployment

> A production-grade multi-tier AWS platform extending the CloudOps Production Platform with a PostgreSQL database tier, encrypted secrets management, GitOps continuous deployment via ArgoCD, and Kubernetes-native load balancing. Built to demonstrate patterns used in **Fintech**, **Telecom**, and **Healthcare** cloud engineering roles.

**Built by:** Uwakwe Obed  
**GitHub:** uwakweobed89-png/CLOUD-OPS-project  
**Stack:** AWS EKS Fargate · ArgoCD · Helm · RDS PostgreSQL · Secrets Manager · KMS · AWS Load Balancer Controller · Terraform · GitHub Actions · Node.js

**Live URL:** `http://k8s-default-cloudops-44226f3fc2-1388412365.us-east-1.elb.amazonaws.com`

---

## Table of Contents

1. [What This Project Demonstrates](#1-what-this-project-demonstrates)
2. [Architecture Overview](#2-architecture-overview)
3. [Project Structure](#3-project-structure)
4. [Phase 1 — RDS PostgreSQL + KMS Encryption](#4-phase-1--rds-postgresql--kms-encryption)
5. [Phase 2 — Secrets Manager + Zero-Secrets Policy](#5-phase-2--secrets-manager--zero-secrets-policy)
6. [Phase 3 — Helm Chart Packaging](#6-phase-3--helm-chart-packaging)
7. [Phase 4 — GitOps with ArgoCD](#7-phase-4--gitops-with-argocd)
8. [Phase 5 — AWS Load Balancer Controller + IRSA](#8-phase-5--aws-load-balancer-controller--irsa)
9. [Phase 6 — App Code: Secrets Manager + RDS Integration](#9-phase-6--app-code-secrets-manager--rds-integration)
10. [Live API Endpoints](#10-live-api-endpoints)
11. [How to Recreate This Project](#11-how-to-recreate-this-project)
12. [Security Design](#12-security-design)
13. [Cost Management](#13-cost-management)
14. [Key Lessons Learned](#14-key-lessons-learned)
15. [Industry Relevance](#15-industry-relevance)
16. [Interview Talking Points](#16-interview-talking-points)

---

## 1. What This Project Demonstrates

This project extends the CloudOps Production Platform (Project 1) by adding a full multi-tier architecture and GitOps deployment pattern. Every component was built and verified working in a live AWS environment.

| Skill | What Was Built |
|-------|---------------|
| Database tier | RDS PostgreSQL 16.3 on db.t3.micro, private subnets, KMS-encrypted at rest |
| Secrets management | AWS Secrets Manager stores DB credentials as JSON, fetched at runtime — never in code |
| IAM least privilege | Dedicated ECS task role and EKS IRSA role, each with only the minimum permissions needed |
| Helm packaging | Kubernetes app packaged as a Helm chart with dev and prod value overrides |
| GitOps | ArgoCD watches GitHub, auto-syncs every 3 minutes, self-heals manual cluster changes |
| Kubernetes networking | AWS Load Balancer Controller provisions real ALBs from Ingress resources |
| IRSA | IAM Roles for Service Accounts — pods get AWS permissions via OIDC, not node-level roles |
| CI/CD integration | GitHub Actions builds Docker image on push, ArgoCD deploys to EKS automatically |

---

## 2. Architecture Overview

```
Internet
    │
    ▼
AWS Application Load Balancer  (provisioned by AWS Load Balancer Controller)
    │
    ▼
EKS Fargate Cluster  ──── ArgoCD watches GitHub repo (every 3 min)
    │                           │
    │                     Helm Chart in Git
    │                     (source of truth)
    ▼
Node.js Pod (x2 replicas)
    │
    ├──► AWS Secrets Manager  ──► KMS Decrypt  ──► DB credentials JSON
    │         (via IRSA)
    ▼
RDS PostgreSQL 16.3
(private subnets, KMS-encrypted, deletion protection on)
```

### How Secrets Flow

```
Pod starts
  │
  ▼
Reads DB_SECRET_ARN from environment variable (set in Helm values.yaml)
  │
  ▼
Calls AWS Secrets Manager GetSecretValue  (allowed by IRSA role)
  │
  ▼
Gets JSON: { username, password, host, port, dbname }
  │
  ▼
Creates PostgreSQL connection pool (pg library)
  │
  ▼
Connects to RDS — password never touches code, image, or task definition
```

### GitOps Flow

```
git push to main branch
  │
  ▼
GitHub Actions: builds Docker image → Trivy scan → push to ECR (latest + SHA tag)
  │
  ▼ (parallel)
ArgoCD detects Helm chart change within 3 minutes
  │
  ▼
ArgoCD applies updated manifests to EKS cluster
  │
  ▼
No manual kubectl commands required
```

---

## 3. Project Structure

```
CLOUD-OPS-project/
├── .github/
│   └── workflows/
│       └── deploy.yml              # GitHub Actions: build → scan → push to ECR
├── app/
│   ├── src/
│   │   └── index.js                # Node.js Express API with Secrets Manager + RDS
│   ├── Dockerfile                  # Multi-stage, non-root user, linux/amd64
│   └── package.json                # Dependencies: express, @aws-sdk/client-secrets-manager, pg
├── helm/
│   └── cloudops-api/
│       ├── Chart.yaml              # Chart identity
│       ├── values.yaml             # Dev defaults (used by ArgoCD)
│       ├── values-prod.yaml        # Production overrides only
│       └── templates/
│           ├── deployment.yaml
│           ├── service.yaml
│           ├── ingress.yaml        # Triggers ALB creation via LBC
│           └── serviceaccount.yaml # IRSA annotation for Secrets Manager access
├── argocd/
│   └── apps/
│       └── cloudops-api.yaml       # ArgoCD Application — points to helm/cloudops-api
├── modules/
│   └── vpc/
│       ├── rds.tf                  # RDS instance, KMS key, subnet group
│       ├── secrets.tf              # Secrets Manager, ECS task role, task definition
│       ├── security_groups.tf      # ALB, App, RDS security groups
│       └── ...
└── eksctl-config.yaml              # EKS Fargate cluster config (includes argocd namespace)
```

---

## 4. Phase 1 — RDS PostgreSQL + KMS Encryption

**File:** `modules/vpc/rds.tf`

### What Was Built

- **RDS PostgreSQL 16.3** on `db.t3.micro` (AWS free tier)
- **KMS key** with automatic annual rotation (`enable_key_rotation = true`)
- **Private subnets only** — database is never reachable from the internet
- **Deletion protection enabled** — `terraform destroy` cannot delete the database
- **Final snapshot** on deletion — no data loss even in emergency teardown

### Key Configuration Decisions

| Setting | Value | Reason |
|---------|-------|--------|
| `multi_az` | `false` | Free tier restriction — enable for production |
| `backup_retention_period` | `0` | Free tier restriction — set to 7 for production |
| `storage_encrypted` | `true` | Always — encrypts data at rest with KMS |
| `deletion_protection` | `true` | Prevents accidental database deletion |
| `engine_version` | `16.3` | Latest stable PostgreSQL at time of build |

### Security Group Design

The RDS security group (`sg-04a90101c1fedd1e0`) uses separate ingress rule resources (not inline rules) to avoid circular dependency issues in Terraform. It allows inbound port 5432 from:
- ECS App security group (for ECS deployments)
- EKS cluster security group (added when EKS was set up)

---

## 5. Phase 2 — Secrets Manager + Zero-Secrets Policy

**File:** `modules/vpc/secrets.tf`

### The Policy

> Passwords never appear in code, Docker images, task definitions, environment variables, or Git history. Ever.

### What Was Built

- **Secrets Manager secret:** `cloudops/rds/credentials` — stores credentials as a JSON object
- **KMS encryption** on the secret itself (same key as RDS)
- **7-day recovery window** — accidental deletion has a safety net
- **IAM policy** `cloudops-read-rds-secret` — allows only `GetSecretValue` and `DescribeSecret` on this specific secret ARN, plus `kms:Decrypt`

### Secret JSON Structure

```json
{
  "username": "cloudops_admin",
  "password": "<value from terraform.tfvars — never committed>",
  "host": "cloudops-postgres.xxxxxx.us-east-1.rds.amazonaws.com",
  "port": 5432,
  "dbname": "cloudopsdb"
}
```

### Why JSON Instead of Individual Keys?

One API call returns all five connection values. The app parses the JSON once at startup instead of making five separate Secrets Manager calls — lower latency, fewer API calls, lower cost.

---

## 6. Phase 3 — Helm Chart Packaging

**Directory:** `helm/cloudops-api/`

### Chart Files

| File | Purpose |
|------|---------|
| `Chart.yaml` | Chart identity — name, version, description |
| `values.yaml` | Dev defaults used by ArgoCD |
| `values-prod.yaml` | Production overrides only (not a full copy) |
| `templates/deployment.yaml` | Pod spec, resource limits, health checks |
| `templates/service.yaml` | ClusterIP service — internal traffic only |
| `templates/ingress.yaml` | Triggers ALB creation via Load Balancer Controller |
| `templates/serviceaccount.yaml` | IRSA annotation linking pod to IAM role |

### Key Ingress Annotations

```yaml
kubernetes.io/ingress.class: alb
alb.ingress.kubernetes.io/scheme: internet-facing
alb.ingress.kubernetes.io/target-type: ip        # Required for Fargate
alb.ingress.kubernetes.io/healthcheck-path: /health
```

`target-type: ip` is required on Fargate — there are no EC2 nodes to register as targets, so the ALB routes directly to pod IP addresses.

### Dev vs Production Values

`values.yaml` sets the dev defaults. `values-prod.yaml` overrides only what changes:

```yaml
# values-prod.yaml — only the differences
replicaCount: 4
resources:
  requests:
    cpu: "512m"
    memory: "1024Mi"
```

---

## 7. Phase 4 — GitOps with ArgoCD

**File:** `argocd/apps/cloudops-api.yaml`

### What ArgoCD Does

ArgoCD runs inside the EKS cluster and watches the GitHub repository. When it detects a change to the Helm chart, it automatically applies the updated manifests — no manual `kubectl apply` or `helm upgrade` needed.

### Sync Policy

```yaml
syncPolicy:
  automated:
    prune: true       # Deleting a file in Git deletes the K8s resource
    selfHeal: true    # Manual kubectl changes get reverted back to Git state
  retry:
    limit: 5
    backoff:
      duration: 5s
      factor: 2
      maxDuration: 3m
```

`selfHeal: true` is the key GitOps principle — Git is the single source of truth. If someone manually changes a replica count in the cluster, ArgoCD corrects it back within 3 minutes.

### ArgoCD Status Reference

| Status | Meaning | Action |
|--------|---------|--------|
| `Synced` | Git and cluster match | Nothing required |
| `OutOfSync` | Cluster differs from Git | ArgoCD will auto-correct |
| `Progressing` | Pods starting up | Wait 2-3 minutes |
| `Healthy` | All resources running and ready | All good |
| `Degraded` | Something failed | `kubectl get events -n default` |

### Accessing the ArgoCD UI

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Open https://localhost:8080
# Username: admin
# Password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

---

## 8. Phase 5 — AWS Load Balancer Controller + IRSA

### Why the Load Balancer Controller Is Needed

Without it, a Kubernetes `Ingress` resource is just a YAML file — nothing actually creates an AWS ALB. The Load Balancer Controller watches for Ingress objects and calls the AWS API to provision real ALBs automatically.

### IRSA — IAM Roles for Service Accounts

IRSA is how EKS pods get AWS permissions without giving permissions to the entire EC2 node. Each service account is annotated with an IAM role ARN. When a pod starts, the EKS pod identity webhook injects temporary credentials for that role into the pod — scoped to that pod only.

```
Pod (using cloudops-api-sa service account)
  │
  ▼
EKS OIDC provider issues token
  │
  ▼
AWS STS AssumeRoleWithWebIdentity
  │
  ▼
Temporary credentials for cloudops-eks-app-role
  │
  ▼
Only permission: GetSecretValue on cloudops/rds/credentials
```

### Setup Steps

```bash
# 1 — Associate OIDC provider with the cluster
eksctl utils associate-iam-oidc-provider \
  --region=us-east-1 \
  --cluster=cloudops-cluster-eks \
  --approve

# 2 — Create IRSA role for Load Balancer Controller
eksctl create iamserviceaccount \
  --cluster=cloudops-cluster-eks \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name=AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::326709068429:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve \
  --region=us-east-1

# 3 — Install LBC via Helm
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=cloudops-cluster-eks \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=us-east-1 \
  --set vpcId=vpc-077d27d9a112d19d0

# 4 — Create IRSA role for app pods
eksctl create iamserviceaccount \
  --cluster=cloudops-cluster-eks \
  --namespace=default \
  --name=cloudops-api-sa \
  --role-name=cloudops-eks-app-role \
  --attach-policy-arn=arn:aws:iam::326709068429:policy/cloudops-read-rds-secret \
  --approve \
  --override-existing-serviceaccounts \
  --region=us-east-1
```

### Required Subnet Tags

The LBC discovers which subnets to use for ALBs via tags. These must be set before the LBC will provision any load balancers:

```bash
# Public subnets (for internet-facing ALBs)
kubernetes.io/role/elb = 1
kubernetes.io/cluster/cloudops-cluster-eks = shared

# Private subnets (for internal ALBs)
kubernetes.io/role/internal-elb = 1
kubernetes.io/cluster/cloudops-cluster-eks = shared
```

---

## 9. Phase 6 — App Code: Secrets Manager + RDS Integration

**File:** `app/src/index.js`

### Startup Sequence

```javascript
initDatabase()           // fetch secret → create pg Pool → test connection
  .then(() => {
    app.listen(PORT)     // only start server after DB attempt completes
  });
```

The app starts even if the database is unreachable — it logs the error and continues. API endpoints degrade gracefully rather than crashing.

### Dependencies Added

```json
{
  "@aws-sdk/client-secrets-manager": "^3.600.0",
  "pg": "^8.12.0"
}
```

### PostgreSQL Connection Pool

```javascript
dbPool = new Pool({
  host: secret.host,
  port: secret.port,
  database: secret.dbname,
  user: secret.username,
  password: secret.password,
  ssl: { rejectUnauthorized: false },
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});
```

A connection pool is used (not a single connection) because it handles reconnection automatically, limits concurrent connections to RDS, and reuses connections for efficiency.

---

## 10. Live API Endpoints

**Base URL:** `http://k8s-default-cloudops-44226f3fc2-1388412365.us-east-1.elb.amazonaws.com`

| Method | Endpoint | Description | Sample Response |
|--------|----------|-------------|-----------------|
| GET | `/` | Service info | `{"service":"cloudops-api","version":"1.0.0","endpoints":[...]}` |
| GET | `/health` | ECS/ALB health check | `{"status":"healthy","timestamp":"...","environment":"development"}` |
| GET | `/api/v1/data` | Main API endpoint | `{"service":"cloudops-api","status":"running","database":"connected"}` |
| GET | `/api/v1/health-detailed` | Full stack health | DB connectivity, latency, Secrets Manager ARN |

### Sample `/api/v1/health-detailed` Response

```json
{
  "status": "healthy",
  "timestamp": "2026-06-30T09:57:47.322Z",
  "environment": "development",
  "database": {
    "connected": true,
    "latency_ms": 47,
    "db_time": "2026-06-30T09:57:47.322Z"
  },
  "secrets_manager": {
    "configured": true,
    "secret_arn": "arn:aws:secretsmanager:us-east-1:326709068429:secret:cloudops/rds/credentials-S2y2yH"
  }
}
```

---

## 11. How to Recreate This Project

### Prerequisites

- AWS CLI configured with appropriate permissions
- `terraform`, `eksctl`, `kubectl`, `helm` installed
- ECR repository with the Docker image pushed

### Step 1 — Provision Infrastructure

```bash
cd environments/dev
terraform apply   # Creates VPC, RDS, Secrets Manager, ECS task role
```

### Step 2 — Create EKS Cluster

```bash
eksctl create cluster --config-file eksctl-config.yaml --timeout 40m
aws eks update-kubeconfig --name cloudops-cluster-eks --region us-east-1
```

### Step 3 — Tag Subnets for ALB Discovery

```bash
# Public subnets
aws ec2 create-tags --resources subnet-0e2d0a1a945e86870 subnet-0a355f3953d30d5ed \
  --tags Key=kubernetes.io/role/elb,Value=1 \
         Key=kubernetes.io/cluster/cloudops-cluster-eks,Value=shared

# Private subnets
aws ec2 create-tags --resources subnet-0c4b81e63c9d3db3f subnet-042b4a91c6706da66 \
  --tags Key=kubernetes.io/role/internal-elb,Value=1 \
         Key=kubernetes.io/cluster/cloudops-cluster-eks,Value=shared
```

### Step 4 — Set Up OIDC + IRSA

```bash
eksctl utils associate-iam-oidc-provider --region=us-east-1 --cluster=cloudops-cluster-eks --approve

# LBC IRSA role
eksctl create iamserviceaccount --cluster=cloudops-cluster-eks --namespace=kube-system \
  --name=aws-load-balancer-controller --role-name=AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::326709068429:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve --region=us-east-1

# App IRSA role
eksctl create iamserviceaccount --cluster=cloudops-cluster-eks --namespace=default \
  --name=cloudops-api-sa --role-name=cloudops-eks-app-role \
  --attach-policy-arn=arn:aws:iam::326709068429:policy/cloudops-read-rds-secret \
  --approve --override-existing-serviceaccounts --region=us-east-1
```

### Step 5 — Install Load Balancer Controller

```bash
helm repo add eks https://aws.github.io/eks-charts && helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system \
  --set clusterName=cloudops-cluster-eks \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=us-east-1 \
  --set vpcId=vpc-077d27d9a112d19d0
```

### Step 6 — Install ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml \
  --server-side --force-conflicts
kubectl apply -f argocd/apps/cloudops-api.yaml
```

ArgoCD will automatically deploy the Helm chart and the ALB will be provisioned within 2-3 minutes.

---

## 12. Security Design

| Layer | Control | Implementation |
|-------|---------|----------------|
| Network | Private subnets | RDS only in private subnets, no public endpoint |
| Network | Security groups | RDS allows only app SG and EKS cluster SG on port 5432 |
| Encryption at rest | KMS | RDS encrypted with customer-managed KMS key (annual rotation) |
| Encryption in transit | SSL | `ssl: { rejectUnauthorized: false }` on pg Pool |
| Secrets | Secrets Manager | Credentials stored as JSON, never in code or images |
| Identity | IRSA | Pods get scoped temporary credentials via OIDC — not node-level roles |
| IAM | Least privilege | App role allows only `GetSecretValue` on its own secret ARN |
| Recovery | Deletion protection | `deletion_protection=true` on RDS prevents accidental loss |
| Recovery | Secret recovery window | 7-day window before secret is permanently deleted |

### ECS Task Role vs EKS IRSA Role

| | ECS Task Role | EKS IRSA Role |
|-|--------------|---------------|
| Name | `cloudops-ecs-task-role` | `cloudops-eks-app-role` |
| Trust principal | `ecs-tasks.amazonaws.com` | EKS OIDC provider |
| Scope | All containers in task | Specific service account in specific namespace |
| Policy | `cloudops-read-rds-secret` | `cloudops-read-rds-secret` |

Both roles have identical permissions. The difference is in how they are assumed — IRSA is more granular because it is scoped to a specific Kubernetes service account rather than all tasks of a given type.

---

## 13. Cost Management

| Resource | Cost | Action |
|----------|------|--------|
| NAT Gateways x2 | ~$65/month | Delete every session, recreate with `terraform apply` |
| EKS cluster | ~$72/month | Delete every session with `eksctl delete cluster` |
| RDS db.t3.micro | Free (750 hrs/month free tier) | Leave running |
| Secrets Manager | ~$0.40/month | Leave running |
| KMS key | ~$1/month | Leave running |
| ECS tasks | ~$1/day | Scale to 0 when not working |
| **Total with session routine** | **~$0/month** | ✅ |

### Production Values (Not Free Tier)

For a real production deployment, update these in `values-prod.yaml` and Terraform:

```hcl
multi_az               = true   # ~$26/month additional
backup_retention_period = 7     # Automatic daily backups
```

---

## 14. Key Lessons Learned

### Kubernetes / EKS

- Fargate requires `alb.ingress.kubernetes.io/target-type: ip` — there are no EC2 nodes to register
- Public subnets must have `kubernetes.io/role/elb=1` tag or the LBC will not find them
- `kubectl apply` fails on large CRDs (ArgoCD applicationsets) — use `--server-side --force-conflicts`
- Always add the `argocd` namespace to the Fargate profile before creating the cluster
- OIDC must be explicitly associated with the cluster before IRSA will work

### IAM / IRSA

- ECS task role and EKS IRSA role are different things — different trust policies, different setup
- `eksctl create iamserviceaccount` handles CloudFormation, trust policy, and annotation automatically
- Use `--override-existing-serviceaccounts` when the service account already exists in the cluster

### Security Groups

- When adding EKS to an existing project, add the EKS cluster security group to the RDS inbound rules
- The EKS cluster security group ID is found with: `aws eks describe-cluster --query "cluster.resourcesVpcConfig.clusterSecurityGroupId"`

### Secrets Manager

- Store all connection values in one JSON secret — one API call, all values
- The app should not crash if Secrets Manager is unreachable — degrade gracefully
- Recovery window of 7 days protects against accidental deletion

---

## 15. Industry Relevance

### Fintech

A payment processing platform needs:
- Encrypted database at rest (KMS) ✅
- Credentials never in code (Secrets Manager) ✅
- Audit trail of all credential access (CloudTrail) ✅
- Zero-downtime deployments (ArgoCD rolling updates) ✅
- Least-privilege IAM (IRSA scoped to one secret) ✅

### Healthcare

A HIPAA-covered system needs:
- PHI encrypted at rest and in transit ✅
- Access controls on database (security groups) ✅
- No secrets in logs or environment variables ✅
- Infrastructure as code for audit reproducibility ✅

### Telecom

A high-throughput CDR processing platform needs:
- Auto-scaling (Helm values support HPA) ✅
- Multi-AZ ready (config in place, toggle for production) ✅
- GitOps for rapid deployment of fixes ✅
- Health endpoints for monitoring integration ✅

---

## 16. Interview Talking Points

**"How do you handle database credentials in containers?"**

> "I never put credentials in environment variables, Docker images, or code. I store them in AWS Secrets Manager encrypted with a customer-managed KMS key. The container only receives the secret ARN as an environment variable. At runtime, the app uses an IRSA role — a Kubernetes service account annotated with an IAM role that has permission to call GetSecretValue on exactly that one secret — to fetch the credentials. Even if someone gets the Docker image or the task definition, they have nothing useful."

**"What is GitOps and have you implemented it?"**

> "GitOps means Git is the single source of truth for both application and infrastructure state. I implemented it using ArgoCD on EKS Fargate. ArgoCD polls the GitHub repo every 3 minutes. When it detects a change to the Helm chart, it applies the update automatically. With selfHeal enabled, if someone manually changes something in the cluster, ArgoCD reverts it back to what Git says within 3 minutes. The cluster always matches the repo — no exceptions."

**"What is the difference between ECS task role and EKS IRSA?"**

> "Both solve the same problem — giving your app code AWS permissions without hardcoding credentials. In ECS, you create a task role with a trust policy for ecs-tasks.amazonaws.com, and all containers in that task assume that role. In EKS, IRSA is more granular — you associate an OIDC provider with the cluster, create a service account annotated with an IAM role ARN, and the EKS pod identity webhook injects temporary credentials scoped to that specific service account. A pod in namespace A using service account A cannot assume the role assigned to service account B in namespace B."

**"Why did you choose Fargate over managed node groups?"**

> "Fargate removes the need to manage EC2 instances entirely. No patching, no capacity planning for nodes, no wasted compute when pods aren't running. The tradeoff is that Fargate requires `target-type: ip` on ALB Ingress (no node-level target groups), and Fargate pods take slightly longer to start because there's no pre-warmed node. For a portfolio project and many production microservice workloads, the operational simplicity outweighs the cold-start cost."

---

*Built as part of the CloudOps Production Platform portfolio — demonstrating production-grade AWS engineering for Fintech, Telecom, and Healthcare roles.*
