#!/usr/bin/env bash
# Recreate the NAT gateways + EIPs (targeted) and scale ECS services back up.
# Counterpart to nat-down.sh.
set -euo pipefail

# cluster:service:desiredCount — keep in sync with nat-down.sh's SERVICES list.
SERVICES=(
  "cloudops-cluster:car-fintech-api-service:1"
)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_DIR="$SCRIPT_DIR/../environments/dev"

# nat-down.sh's targeted destroy of the NAT gateways also fully destroys the
# private route tables AND their subnet associations (not just an in-place
# route update — Terraform pulls in the full dependent resource on destroy).
# So recreating just the NAT gateways + route tables here isn't enough; the
# associations must be explicitly targeted too, or the private subnets stay
# unassociated with any route table after this runs.
echo "== Recreating NAT gateways + EIPs (targeted) =="
cd "$ENV_DIR"
terraform init -input=false >/dev/null
terraform apply -input=false -auto-approve \
  -target=module.vpc.aws_eip.nat_az1 \
  -target=module.vpc.aws_eip.nat_az2 \
  -target=module.vpc.aws_nat_gateway.az1 \
  -target=module.vpc.aws_nat_gateway.az2 \
  -target=module.vpc.aws_route_table.private_az1 \
  -target=module.vpc.aws_route_table.private_az2 \
  -target=module.vpc.aws_route_table_association.private_az1 \
  -target=module.vpc.aws_route_table_association.private_az2

echo "== Waiting ~60s for NAT gateways to pass health checks before scaling up =="
sleep 60

echo "== Scaling ECS services back up =="
for entry in "${SERVICES[@]}"; do
  cluster="${entry%%:*}"
  rest="${entry#*:}"
  service="${rest%%:*}"
  count="${rest##*:}"
  echo "$cluster/$service: desired=0 -> $count"
  aws ecs update-service --cluster "$cluster" --service "$service" --desired-count "$count" >/dev/null
done

echo "Done. Give tasks a minute to pull images and reach steady state."
