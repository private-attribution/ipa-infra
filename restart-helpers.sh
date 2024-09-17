#!/bin/bash

helm uninstall h1
helm uninstall h2
helm uninstall h3

helm install h1 .
helm install h2 .
helm install h3 .
