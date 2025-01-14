#!/bin/bash

#helm uninstall rc
helm uninstall h1
helm uninstall h2
helm uninstall h3

# helm uninstall prometheus
NAMESPACE_NAME="monitoring"
MONITORING_RELEASE_NAME="monitoring"

helm uninstall $MONITORING_RELEASE_NAME -n $NAMESPACE_NAME