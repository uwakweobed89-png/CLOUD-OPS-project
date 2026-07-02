#!/usr/bin/env bash
# Scale down all apps in the shared ECS cluster, then tear down just the NAT
# gateways + their EIPs (targeted — never a bare `terraform destroy`).
#
# NAT gateways cost ~$65-70/month combined even when idle. Run this when
# pausing work; run nat-up.sh to bring everything back.
#
# Add "cluster:service" pairs here as more apps land in the shared cluster.
set -euo pipefail

SERVICES=(
  "cloudops-cluster:car-fintech-api-service"
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

echo "== Destroying NAT gateways + EIPs (targeted, VPC/RDS untouched) =="
cd "$ENV_DIR"
terraform init -input=false >/dev/null
terraform destroy -input=false -auto-approve \
  -target=module.vpc.aws_nat_gateway.az1 \
  -target=module.vpc.aws_nat_gateway.az2 \
  -target=module.vpc.aws_eip.nat_az1 \
  -target=module.vpc.aws_eip.nat_az2

echo "Done. Private-subnet workloads have no internet egress until nat-up.sh runs."
