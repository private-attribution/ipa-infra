#!/bin/bash
# Check if the user provided the desired node count as an argument
if [ $# -ne 1 ]; then
    echo "Error: Please provide the desired node count as an argument."
    exit 1
fi
NODE_COUNT=$1
for i in {1..3}; do
    HELM_RELEASE="h$i"
    # Run helm command
    helm install ${HELM_RELEASE} . --set shardCount=${NODE_COUNT}
done
