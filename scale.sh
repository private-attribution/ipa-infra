#!/bin/bash
# Check if the user provided the desired shard count as an argument
if [ $# -ne 1 ]; then
    echo "Error: Please provide the desired shard count as an argument."
    exit 1
fi
SHARD_COUNT=$1
for i in {1..3}; do
    HELM_RELEASE="h$i"
    NODEGROUP_NAME="helper$i"
    # Run eksctl command
    eksctl scale nodegroup --cluster=open-helpers --nodes=${SHARD_COUNT} --name=${NODEGROUP_NAME} --nodes-min=${SHARD_COUNT} --nodes-max=${SHARD_COUNT} --wait
done
