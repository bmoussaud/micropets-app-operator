#@ load("@ytt:yaml", "yaml")
---
#@ def config():
tap:
  namespace: tap-install
  devNamespace: dev-tap
  devNamespace: dev-tap
  logo: #@ base64.encode(data.read('tap-logo.png'))
  
  #! Set Backstage catalogs to include by default.
  catalogs:
  - https://github.com/bmoussaud/micropets-app/blob/master/catalog-info.yaml

  registry:
    host: registry.tanzu.corp
    repositories:
      buildService: tanzu/tanzu-build-service
      ootbSupplyChain: tanzu/tanzu-supply-chain

  domains:
    main: apps.tanzu.corp    
#@ end
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: tap-install-gitops
  namespace: tap-install-gitops
data:
  tap-config.yml: #@ yaml.encode(config())
