#!/bin/bash
# Check if the user provided the desired shard count as an argument
if [ $# -ne 1 ]; then
    echo "Error: Please provide the desired shard count as an argument."
    exit 1
fi
SHARD_COUNT=$1

#helm install rc .

for i in {1..3}; do
    HELM_RELEASE="h$i"
    # Run helm command
    helm install ${HELM_RELEASE} . --set shardCount=${SHARD_COUNT}
done

# Set the namespace name
NAMESPACE_NAME="monitoring"
# Check if the namespace exists
if kubectl get namespace $NAMESPACE_NAME &> /dev/null; then
  echo "Namespace $NAMESPACE_NAME already exists."
else
  # Create the namespace
  echo "Creating namespace $NAMESPACE_NAME..."
  kubectl create namespace $NAMESPACE_NAME
  if [ $? -eq 0 ]; then
    echo "Namespace $NAMESPACE_NAME created successfully."
  else
    echo "Error creating namespace $NAMESPACE_NAME: $?"
    exit 1
  fi
fi

# Set the repository name and URL
REPO_NAME="prometheus-community"
REPO_URL="https://prometheus-community.github.io/helm-charts"
# Check if the repository already exists
if helm repo list | grep -q $REPO_NAME; then
    echo "Error: Repository $REPO_NAME already exists. Skipping..."
    exit 0
else
    # Try to add the repository
    helm repo add $REPO_NAME $REPO_URL
    if [ $? -eq 0 ]; then
        echo "Repository $REPO_NAME added successfully."
    else
        echo "Error adding repository $REPO_NAME: $(helm repo add $REPO_NAME $REPO_URL 2>&1)"
        exit 1
    fi
fi

MONITORING_RELEASE_NAME="monitoring"
helm upgrade -i $MONITORING_RELEASE_NAME prometheus-community/prometheus \
    --namespace $NAMESPACE_NAME \
    --set server.persistentVolume.storageClass="gp2"
