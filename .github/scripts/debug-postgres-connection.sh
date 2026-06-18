#!/bin/bash

echo "=== PostgreSQL Connection Debug ==="

NAMESPACE="${1:-default}"
LABEL_SELECTOR="${2:-app=postgresql}"

echo "Namespace: $NAMESPACE"
echo "Label Selector: $LABEL_SELECTOR"
echo ""

echo "Finding pods..."
kubectl get pods -n "$NAMESPACE" -l "$LABEL_SELECTOR"

echo ""
echo "Pod details:"
POSTGRES_POD=$(kubectl get pods -n "$NAMESPACE" \
  -l "$LABEL_SELECTOR" \
  -o jsonpath='{.items[0].metadata.name}')

if [ -z "$POSTGRES_POD" ]; then
  echo "ERROR: No pod found!"
  exit 1
fi

echo "Pod name: $POSTGRES_POD"
echo "Pod status: $(kubectl get pod -n "$NAMESPACE" "$POSTGRES_POD" -o jsonpath='{.status.phase}')"

echo ""
echo "Testing database connection..."
kubectl exec -n "$NAMESPACE" "$POSTGRES_POD" -- psql --version

echo ""
echo "Listing databases (requires POSTGRES_PASSWORD and POSTGRES_USER env vars)..."
kubectl exec -n "$NAMESPACE" "$POSTGRES_POD" \
  --env "PGPASSWORD=${POSTGRES_PASSWORD:-}" \
  -- psql -U "${POSTGRES_USER:-postgres}" -l
