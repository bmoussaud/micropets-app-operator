#!/bin/bash
set -x 
CLUSTER_NAME=aks-eu-tap-2
REGISTRY_NAME=akseutap2registry
TBS_VERSION=1.7.2
INSTALL_REPO=tanzu-application-platform

source ~/.kube/acr/.${REGISTRY_NAME}.config

TBS_PACKAGE=$(kubectl get package -n tap-install | grep buildservice.tanzu.vmware.com | awk {'print $1'} )
echo "TBS_PACKAGE ${TBS_PACKAGE}"
TBS_VERSION=$(kubectl get -n tap-install package  ${TBS_PACKAGE} -o=jsonpath='{.spec.version}')
echo "TBS_VERSION ${TBS_VERSION}"
echo "imgpkg copy -b registry.tanzu.vmware.com/tanzu-application-platform/full-tbs-deps-package-repo:${TBS_VERSION} --to-repo=${INSTALL_REGISTRY_HOSTNAME}/${INSTALL_REPO}/tbs-full-deps"

echo "add tbs-full-deps-repository tbs-full-deps:${TBS_VERSION}"
tanzu package repository add tbs-full-deps-repository --url ${INSTALL_REGISTRY_HOSTNAME}/${INSTALL_REPO}/tbs-full-deps:${TBS_VERSION} --namespace tap-install
echo "package install full-tbs-deps.tanzu.vmware.com / ${TBS_VERSION} "
tanzu package install full-tbs-deps -p full-tbs-deps.tanzu.vmware.com -v ${TBS_VERSION} -n tap-install
