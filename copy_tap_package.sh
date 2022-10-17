#!/bin/bash

set -x 
CLUSTER_NAME=aks-eu-tap-2
REGISTRY_NAME=akseutap2registry
TAP_VERSION=1.3.0

INSTALL_REPO=tanzu-application-platform

source ~/.kube/acr/.${REGISTRY_NAME}.config

imgpkg copy -b  registry.tanzu.vmware.com/tanzu-application-platform/tap-packages:${TAP_VERSION} --to-repo ${INSTALL_REGISTRY_HOSTNAME}/${INSTALL_REPO}/tap-packages   --include-non-distributable-layers --concurrency 2

