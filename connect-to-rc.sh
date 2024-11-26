#!/bin/bash
# Find the pod with the label "app: report-collector"
REPORT_COLLECTOR_POD=$(kubectl get pods -l app=report-collector --output=jsonpath='{.items[0].metadata.name}')
if [ -z "$REPORT_COLLECTOR_POD" ]; then
  echo "No pod found with label 'app: report-collector'"
  exit 1
fi
echo "Found pod: $REPORT_COLLECTOR_POD"
# Run the command on the pod
kubectl exec --stdin --tty "$REPORT_COLLECTOR_POD" -- /bin/bash
