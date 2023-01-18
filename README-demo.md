# Tanzu Application Plaform Demo

## Prepare the demo

### Deploy Carvel Tools

using opensource distribution
```
make kapp-controler secretgen-controller
```

or using tanzu distribution

```
make tanzu-cluster-essentials
```

### Relocate the TAP version on a local registry (optional)

You can use the pivnet or central vmregistry (registry.tanzu.vmware.com) but it can be convenient to copy the bundles to a local registry located closed the K8S cluster.

Using the Azure Container Registry [copy_tap_package.sh]()

```shell

./copy_tap_package.sh akseutap4registry 1.4.0-rc.16

#!/bin/bash

CLUSTER_NAME=aks-eu-tap-3
REGISTRY_NAME=akseutap3registry
TAP_VERSION=1.3.1
INSTALL_REPO=tanzu-application-platform

INSTALL_REGISTRY_HOSTNAME=${REGISTRY_NAME}.azurecr.io
INSTALL_REGISTRY_USERNAME=
INSTALL_REGISTRY_PASSWORD=

docker login ${INSTALL_REGISTRY_HOSTNAME} -u ${INSTALL_REGISTRY_USERNAME} -p ${INSTALL_REGISTRY_PASSWORD}
docker login registry.tanzu.vmware.com

imgpkg copy -b  registry.tanzu.vmware.com/tanzu-application-platform/tap-packages:${TAP_VERSION} --to-repo ${INSTALL_REGISTRY_HOSTNAME}/${INSTALL_REPO}/tap-packages   --include-non-distributable-layers --concurrency 2
```
TBS 

```shell
#!/bin/bash
TBS_VERSION=1.7.2
imgpkg copy -b registry.tanzu.vmware.com/tanzu-application-platform/full-tbs-deps-package-repo:${TBS_VERSION} --to-repo=${INSTALL_REGISTRY_HOSTNAME}/${INSTALL_REPO}/tbs-full-deps
tanzu package repository add tbs-full-deps-repository --url ${INSTALL_REGISTRY_HOSTNAME}/${INSTALL_REPO}/tbs-full-deps:${TBS_VERSION}  --namespace tap-install  
tanzu package install full-tbs-deps -p full-tbs-deps.tanzu.vmware.com -v ${TBS_VERSION} -n tap-install

```

Scanner config

https://docs-staging.vmware.com/en/draft/VMware-Tanzu-Application-Platform/1.3/tap/GUID-scst-scan-install-scanners.html


### Namespace Provisioner

Doc: https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.4/tap/namespace-provisioner-tutorials.html

The registry-credentials secret referenced by the Tanzu Build Service is added to tap-install and exported to all namespaces.

```shell
#!/bin/bash
source /Users/benoitmoussaud/.kube/acr/.akseutap4registry.config
tanzu secret registry add tbs-registry-credentials --server ${INSTALL_REGISTRY_HOSTNAME} --username ${INSTALL_REGISTRY_USERNAME} --password ${INSTALL_REGISTRY_PASSWORD} --export-to-all-namespaces --yes --namespace tap-install
```

```shell
kubectl create namespace tap-14-dev
kubectl label namespaces tap-14-dev tap.mytanzu.xyz/my-tap-ns=""
kubectl get secrets,serviceaccount,rolebinding,pods,workload,configmap -n tap-14-dev

```

### External secret operator


Azure: Create an Key vault Deployment name: `bmoussaud-keyvault`, Rg `mytanzu.xyz`
Doc: 
* https://external-secrets.io/v0.7.1/provider/azure-key-vault/
* https://blog.container-solutions.com/tutorial-external-secrets-with-azure-keyvault

```shell
CLUSTER_NAME=aks-eu-tap-4
KEY_VAULT=bmoussaud-keyvault
KEY_VAULT_RG=mytanzu.xyz
tanzu package install external-secrets   -p external-secrets.apps.tanzu.vmware.com --version  0.6.1+tap.2 -n tap-install
az aks show --resource-group $(CLUSTER_NAME)  --name $(CLUSTER_NAME)   --query 'identityProfile.kubeletidentity.objectId' -o tsv
KUBELET_IDENTITY_OBJECT_ID=$(az aks show --resource-group $(CLUSTER_NAME)   --name $(CLUSTER_NAME)   --query 'identityProfile.kubeletidentity.objectId' -o tsv)
echo ${KUBELET_IDENTITY_OBJECT_ID}
az keyvault set-policy --name $(KEY_VAULT) --resource-group  $(KEY_VAULT_RG)  --object-id "${KUBELET_IDENTITY_OBJECT_ID}" --certificate-permissions get --secret-permissions get
```

### Deploy [Tanzu Application Platform]()

```shell
make tap
```

Configuration: [tap/tap-install-config.yml](tap/tap-install-config.yml)

```yaml
#@ def config():
tap:  
  version: "1.3.0-build.24"
  namespace: tap-install
  devNamespace: dev-tap
  logo: #@ base64.encode(data.read('tap-logo.png'))

  supply_chain: testing 
  #!(or basic or supply_chain: testing_scanning)

  #! Set Backstage catalogs to include by default.
  catalogs:
  - https://github.com/bmoussaud/micropets-app/blob/master/catalog-info.yaml

  registry:
    hostold: harbor.mytanzu.xyz
    host: akseutap3registry.azurecr.io
    repositories:
      buildService: library/tanzu-build-service
      ootbSupplyChain: library/tanzu-supply-chain

  domains:
    main: apps.eu.aks.mytanzu.xyz
#@ end
```
Credentials: [tap/tap-install-secrets.yml]()
```yaml
#@ def config():
tap:
  credentials:
    #! Pick one registry for downloading images: Tanzu Network or Pivotal Network
    #! (use tanzuNet as key).
    tanzuNet:
      host: akseutap3registry.azurecr.io    
      username: bmoussaud@vmware.com
      password: <xxxxyyyzzz>
    registry:
      username: admin
      password: <xxxxyyyzzz>
```

Even if the output the command is 
```shell
kapp: Error: waiting on reconcile app/tap-install-gitops (kappctrl.k14s.io/v1alpha1) namespace: tap-install-gitops:
  Finished unsuccessfully (Reconcile failed:  (message: Deploying: Error (see .status.usefulErrorMessage for details)))
```

Check the status of the deployed packages (35) using:
```shell
watch kubectl get app -A
```

Get the TAP-GUI ip adresse
```shell
make tap-gui-ip
```

### Deploy the Micropets supplychains 

Deploy the [micropet-supplychains](suppychains) && [micropet-deliveries](deliveries)
```shell
make kpack
make supplychain 
make delivery
```

### Deploy the Micropets accelerators

Deploy the [micropet-java-service-accelerator](https://github.com/bmoussaud/micropet-java-service-accelerator/tree/main/)
Deploy the [micropet-golang-service-accelerator](https://github.com/bmoussaud/micropet-golang-service-accelerator/tree/main/)

```shell
tanzu acc create micropet-java-service-accelerator --git-repo https://github.com/bmoussaud/micropet-java-service-accelerator --git-branch main --interval 5s
tanzu acc create micropet-golang-service-accelerator --git-repo https://github.com/bmoussaud/micropets-golang-service-accelerator --git-branch main --interval 5s
```

### Deploy the Micropets application
Deploy the [micropet-app](https://github.com/bmoussaud/micropets-app)

```shell
git clone https://github.com/bmoussaud/micropets-app-gitops.git
kapp deploy --into-ns dev-tap -c -a workloads -f <(ytt -f generators/workloads --data-value environment=azure/aks-eu-tap-3)
```

## Run the Demo

### Display the Workloads 

In a terminal, split the window to display the output of these 2 commands

```shell
watch kubectl tree workload birds -n dev-tap 
watch tanzu apps wld get birds -n dev-tap
tanzu apps workload tail birds -n dev-tap
```

Display [Tilt Console http://localhost:10350/](http://localhost:10350/)

### Scenario Accelerator

1. Go to the Tap-gui console in the accelerator page
1. Select `Micropets Java Service`
1. Provide values
    * name: my-bird-service
    * Kind: Bird
1. Click Next and Generate the zip file
1. Expand the zip file 
1. In a Terminal, go to uncompressed files 
  * open VSCode `code .`
  * build the application using maven `./mvnw package`
  * Run the java application `java -jar target/birds-0.0.1-SNAPSHOT.jar`
  * Access the service [http://localhost:8080](http://localhost:8080)
  * Stop the application
1. Trigger the Workload
  * In VScode, Select to the `Tiltfile -> Tanzu: Live Update Start`
  * open the [Tilt Console](http://localhost:10350/)
  * open the TAP GUI/Workload
1. Wait for the end of the execution of the supply chain and access the application
  * using the proxy provided by [Tilt](http://localhost:8080)
  * using the exposed service url  displayed by the `tanzu app wld get <>`
1. Modify the Code (ex BirdControler, load() method) and show only the modified classes are uploaded and the JVM reloaded.
1. (Optionaly) Remote Debugging. In VSCode, Select the workload file (config/workload.yaml) and Tanzu: Remote Debug Start

### Clean up

```shell
tanzu apps workload delete birds -n dev-tap
```
