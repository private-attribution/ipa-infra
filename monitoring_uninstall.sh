#!/bin/bash

# helm uninstall prometheus
NAMESPACE_NAME="monitoring"
MONITORING_RELEASE_NAME="monitoring"

helm uninstall $MONITORING_RELEASE_NAME -n $NAMESPACE_NAME