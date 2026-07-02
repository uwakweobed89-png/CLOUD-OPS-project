#!/usr/bin/env bash
# Scale down all apps in the shared ECS cluster, stop their RDS instances,
# then tear down just the NAT gateways + their EIPs (targeted — never a bare
# `terraform destroy`).
#
# NAT gateways cost ~$65-70/month combined even when idle; a running RDS
# instance costs ~$14-15/month. Run this when pausing work for a while; run
# nat-up.sh to bring everything back.
#
# Note: AWS auto-restarts a stopped RDS instance after 7 days (it won't stay
# stopped indefinitely) — this is a short-pause cost-saver, not a way to
# permanently shut the database off. For that, delete it (much harder to
# reverse, not what this script does).
#
# Add "cluster:service" pairs / RDS instance ids here as more apps land in
# the shared cluster.
set -euo pipefail

SERVICES=(
  "cloudops-cluster:car-fintech-api-service"
)

RDS_INSTANCES=(
  "car-fintech-postgres"
)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_DIR="$SCRIPT_DIR/../environments/dev"

echo "== Scaling ECS services to 0 =="
for pair in "${SERVICES[@]}"; do
  cluster="${pair%%:*}"
  service="${pair##*:}"
  current=$(aws ecs describe-services --cluster "$cluster" --services "$service" \
    --query "services[0].desiredCount" --output text)
  echo "$cluster/$service: desired=$current -> 0 (was $current)"
  aws ecs update-service --cluster "$cluster" --service "$service" --desired-count 0 >/dev/null
done

echo "== Waiting for tasks to drain =="
for pair in "${SERVICES[@]}"; do
  cluster="${pair%%:*}"
  service="${pair##*:}"
  aws ecs wait services-stable --cluster "$cluster" --services "$service"
done

echo "== Stopping RDS instances =="
for db in "${RDS_INSTANCES[@]}"; do
  status=$(aws rds describe-db-instances --db-instance-identifier "$db" --query "DBInstances[0].DBInstanceStatus" --output text)
  if [ "$status" = "available" ]; then
    echo "$db: available -> stopping"
    aws rds stop-db-instance --db-instance-identifier "$db" >/dev/null
  else
    echo "$db: already $status"
  fi
done

echo "== Destroying NAT gateways + EIPs (targeted, VPC untouched) =="
cd "$ENV_DIR"
terraform init -input=false >/dev/null
terraform destroy -input=false -auto-approve \
  -target=module.vpc.aws_nat_gateway.az1 \
  -target=module.vpc.aws_nat_gateway.az2 \
  -target=module.vpc.aws_eip.nat_az1 \
  -target=module.vpc.aws_eip.nat_az2

echo "Done. Private-subnet workloads have no internet egress, and RDS is stopping, until nat-up.sh runs."
