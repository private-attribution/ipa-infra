#!/bin/bash
# Check if the user provided the desired shard count as an argument
if [ $# -ne 1 ]; then
    echo "Error: Please provide the desired shard count as an argument."
    exit 1
fi
SHARD_COUNT=$1
for i in {1..3}; do
    HELM_RELEASE="h$i"
    # Run helm command
    helm install ${HELM_RELEASE} . --set shardCount=${SHARD_COUNT}
done
