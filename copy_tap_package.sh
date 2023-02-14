#!/bin/bash

set -x 
REGISTRY_NAME=$1
TAP_VERSION=$2

INSTALL_REPO=tanzu-application-platform

source ~/.kube/acr/.${REGISTRY_NAME}.config

echo "INSTALL_REGISTRY_HOSTNAME ${INSTALL_REGISTRY_HOSTNAME}"
echo "INSTALL_REPO ${INSTALL_REPO}"
echo "TAP_VERSION ${TAP_VERSION}"
imgpkg copy -b  registry.tanzu.vmware.com/tanzu-application-platform/tap-packages:${TAP_VERSION} --to-repo ${INSTALL_REGISTRY_HOSTNAME}/${INSTALL_REPO}/tap-packages   --include-non-distributable-layers --concurrency 5

