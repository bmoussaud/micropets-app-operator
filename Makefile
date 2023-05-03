MICROPETS_SP_NS=dev-tap
SECRET_OUTPUT_FILE=.secrets.yaml
REGISTRY_NAME=akseutap5registry

namespace:
	kubectl create namespace $(MICROPETS_SP_NS) --dry-run=client -o yaml | kubectl apply -f -
	kubectl get namespace $(MICROPETS_SP_NS) 

kpack: namespace		
	source ~/.kube/acr/.$(REGISTRY_NAME).config
	ytt --ignore-unknown-comments --data-value-yaml registry.server=${INSTALL_REGISTRY_HOSTNAME} --data-value-yaml registry.username=${INSTALL_REGISTRY_USERNAME} --data-value-yaml registry.password=${INSTALL_REGISTRY_PASSWORD}  -f kpack | kapp deploy -c --yes  --into-ns $(MICROPETS_SP_NS) -a micropet-kpack -f-

supplychain: gen_secrets
	ytt --ignore-unknown-comments -f supplychains --data-values-file $(SECRET_OUTPUT_FILE) | kapp deploy -c --yes --into-ns $(MICROPETS_SP_NS) -a micropet-supplychain -f-
	-rm $(SECRET_OUTPUT_FILE)

.PHONY: delivery
delivery: gen_secrets	
	ytt --ignore-unknown-comments -f delivery --data-values-file $(SECRET_OUTPUT_FILE) | kapp deploy -c --yes  --into-ns $(MICROPETS_SP_NS) -a micropet-delivery -f-
	-rm $(SECRET_OUTPUT_FILE)

gen_secrets:	
	SECRET_OUTPUT_FILE=$(SECRET_OUTPUT_FILE) scripts/gen_secrets.sh

undelivery: namespace
	kapp delete -a micropet-delivery

unsupplychain:	
	kapp delete -a micropet-supplychain

local-kapp:
	ytt --ignore-unknown-comments -f kapp/service -f kapp/values/kapp-local-values.yaml

local-knative:
	ytt --ignore-unknown-comments -f kapp/kservice -f kapp/values/kapp-local-values.yaml

local-kapp-gui:
	ytt --ignore-unknown-comments -f kapp/service -f kapp/values/kapp-local-values-gui.yaml

deploy-knative-app:
	ytt --ignore-unknown-comments -f kapp/kservice -f kapp/values/kapp-local-values.yaml | kapp deploy -c --yes --dangerous-override-ownership-of-existing-resources -n  $(MICROPETS_SP_NS) --into-ns $(MICROPETS_SP_NS) -a micropet-local-knative -f-
	kubectl get ksvc dogs-kservice

undeploy-knative-app:
	kapp  delete --yes -a micropet-local-knative -n  $(MICROPETS_SP_NS) 

sample-kapp-controler:
	kubectl apply -f kapp-sample.yaml

sample-unkapp-controler:
	kubectl delete -f kapp-sample.yaml

deploy-knative:
	ytt --ignore-unknown-comments -f knative \
			-f https://github.com/knative/serving/releases/download/knative-v1.0.0/serving-crds.yaml  \
			-f https://github.com/knative/serving/releases/download/knative-v1.0.0/serving-core.yaml  \
		-f https://github.com/knative/net-istio/releases/download/knative-v1.0.0/net-istio.yaml   \
	| kapp deploy -c --yes -n default -a knative-serving-1.0 -f-
	kubectl --namespace istio-system get service istio-ingressgateway

cnb:
	kapp deploy -c --yes -a kpack -f https://github.com/pivotal/kpack/releases/download/v0.5.3/release-0.5.3.yaml

fluxcd:
	kubectl create clusterrolebinding gitops-toolkit-admin --clusterrole=cluster-admin --serviceaccount=gitops-toolkit:default
	kubectl create namespace gitops-toolkit
	kapp deploy -c --yes -a gitops-toolkit --into-ns gitops-toolkit -f https://github.com/fluxcd/source-controller/releases/download/v0.22.4/source-controller.crds.yaml -f https://github.com/fluxcd/source-controller/releases/download/v0.22.4/source-controller.deployment.yaml

cert-manager:
	kapp deploy -c --yes -a cert-manager -f https://github.com/jetstack/cert-manager/releases/download/v1.7.2/cert-manager.yaml

kapp-controler:
	kapp deploy -c --yes -a kapp-controler -f https://github.com/vmware-tanzu/carvel-kapp-controller/releases/download/v0.41.2/release.yml

secretgen-controller:
	kapp deploy -c --yes -a secretgen-controller -f https://github.com/vmware-tanzu/carvel-secretgen-controller/releases/download/v0.11.0/release.yml


CLUSTER_ESSENTIAL_INSTALL_BUNDLE=tanzu-cluster-essentials/cluster-essentials-bundle@sha256:79abddbc3b49b44fc368fede0dab93c266ff7c1fe305e2d555ed52d00361b446
tanzu-cluster-essentials:		
	source ~/.kube/acr/.$(REGISTRY_NAME).config
	imgpkg copy -b  registry.tanzu.vmware.com/$(CLUSTER_ESSENTIAL_INSTALL_BUNDLE) --to-repo $(REGISTRY_NAME).azurecr.io/tanzu-cluster-essentials/cluster-essentials-bundle --include-non-distributable-layers --concurrency 5
	kubectl create namespace tanzu-cluster-essentials --dry-run=client -o yaml | kubectl apply -f -
	imgpkg pull -b $(REGISTRY_NAME).azurecr.io/$(CLUSTER_ESSENTIAL_INSTALL_BUNDLE) -o /tmp/bundle/

	echo "## Deploying kapp-controller"
	ytt -f /tmp/bundle/kapp-controller/config/ -f /tmp/bundle/registry-creds/ --data-value-yaml registry.server=${INSTALL_REGISTRY_HOSTNAME} --data-value-yaml registry.username=${INSTALL_REGISTRY_USERNAME} --data-value-yaml registry.password=${INSTALL_REGISTRY_PASSWORD} --data-value-yaml kappController.deployment.concurrency=10 | kbld -f- -f /tmp/bundle/.imgpkg/images.yml | kapp deploy --yes -a kapp-controller -n tanzu-cluster-essentials -f-

	echo "## Deploying secretgen-controller"
	ytt -f /tmp/bundle/secretgen-controller/config/ -f /tmp/bundle/registry-creds/ --data-value-yaml registry.server=${INSTALL_REGISTRY_HOSTNAME} --data-value-yaml registry.username=${INSTALL_REGISTRY_USERNAME} --data-value-yaml registry.password=${INSTALL_REGISTRY_PASSWORD}| kbld -f- -f /tmp/bundle/.imgpkg/images.yml | kapp deploy --yes -a secretgen-controller -n tanzu-cluster-essentials -f-

	@rm  -rf /tmp/bundle/

.PHONY: tap
available-version:
	imgpkg tag list -i registry.tanzu.vmware.com/tanzu-application-platform/tap-packages | sort -V

tap:
	source ~/.kube/acr/.$(REGISTRY_NAME).config && ytt -f tap --data-value-yaml git.token=${GIT_SSH_PASSWORD} --data-value-yaml registry.server=${INSTALL_REGISTRY_HOSTNAME} --data-value-yaml registry.username=${INSTALL_REGISTRY_USERNAME} --data-value-yaml registry.password=${INSTALL_REGISTRY_PASSWORD} --data-value repository=https://github.com/bmoussaud/tap-install-gitops | kapp deploy --yes -c -a tap-install-gitops -f-

tap-gui-ip:
# az network dns record-set a add-record --resource-group mytanzu.xyz --zone-name mytanzu.xyz --record-set-name "*.tap4.eu.aks"  --ipv4-address  1.2.3.4
	kubectl get HTTPProxy  -n tap-gui tap-gui
	kubectl get HTTPProxy  -n tap-gui tap-gui -o json | jq ".status.loadBalancer.ingress[0].ip"

kapp-controler-tkgm:
	kubectl apply -f https://github.com/vmware-tanzu/carvel-kapp-controller/releases/download/v0.31.0/release.yml

contour:
	kapp deploy --yes -c -a contour -f https://projectcontour.io/quickstart/contour.yaml
	
cartographer: 
	kubectl create namespace cartographer-system --dry-run=client -o yaml | kubectl apply -f -
	kapp deploy -c --yes -a cartographer  -f https://github.com/vmware-tanzu/cartographer/releases/download/v0.4.0-build.1/cartographer.yaml
	
# ASO CRD file is so huge => performance issue with KAPP
# 
register-provider:
	az provider register --namespace  Microsoft.DBforPostgreSQL


aso: 
	kubectl apply --server-side=true -f https://github.com/Azure/azure-service-operator/releases/download/v2.0.0-beta.4/azureserviceoperator_v2.0.0-beta.4.yaml
	
	source ~/.azure/rbac/azure-service-operator-contributor-aks-eu-tap-3.config \
		&& ytt --ignore-unknown-comments --data-values-env AZURE \
		-f azure-service-operator  | kapp deploy -a aso-secrets --yes -c -f-		

	kubectl wait deployment -n azureserviceoperator-system -l app=azure-service-operator-v2 --for=condition=Available=True

aso-instance.ytt: 
	@-rm azure-service-operator-instance/.$@.yaml	
	ytt -f azure-service-operator-instance --ignore-unknown-comments > azure-service-operator-instance/.$@.yaml	

aso-instance: aso-instance.ytt
	kubectl apply -f azure-service-operator-instance/.$@.ytt.yaml

aso-instance-check:		
	kubectl tree resourcegroups.resources.azure.com -n database-instances-fr micropet-db-fr

aso-instance-wait: aso-instance-check
	kubectl wait flexibleservers.dbforpostgresql.azure.com bmoussaud-micropetstore-psql-srv -n database-instances-fr --for=condition=Ready --timeout=5m 
	kubectl wait flexibleserversdatabases.dbforpostgresql.azure.com bmoussaud-micropetstore-psql -n database-instances-fr   --for=condition=Ready --timeout=5m

undeploy-aso:
	kubectl delete --server-side=true -f https://github.com/Azure/azure-service-operator/releases/download/v2.0.0-beta.3/azureserviceoperator_v2.0.0-beta.3.yaml

undeploy-aso-instance: aso-instance.ytt
	kubectl delete -f azure-service-operator-instance/.aso-instance.ytt.yaml
	

POSTGRESQL_OPERATION_VERSION=2.0.0
TDS_VERSION=1.6.0
postgres-tanzu-operator:
	imgpkg copy -b registry.tanzu.vmware.com/packages-for-vmware-tanzu-data-services/tds-packages:$(TDS_VERSION) --to-repo ${INSTALL_REGISTRY_HOSTNAME}/packages-for-vmware-tanzu-data-services/tds-packages
	tanzu secret registry add $(INSTALL_REGISTRY_HOSTNAME)  --username $(INSTALL_REGISTRY_USERNAME) --password $(INSTALL_REGISTRY_PASSWORD) --server $(INSTALL_REGISTRY_HOSTNAME) --export-to-all-namespaces --yes
	tanzu package repository add tanzu-data-services-repository --url ${INSTALL_REGISTRY_HOSTNAME}/packages-for-vmware-tanzu-data-services/tds-packages:$(TDS_VERSION) --namespace postgres-tanzu-operator --create-namespace
	tanzu package install postgres-tanzu-operator --package-name postgres-operator.sql.tanzu.vmware.com --version $(POSTGRESQL_OPERATION_VERSION) --namespace postgres-tanzu-operator --create-namespace
	kubectl wait deployment -n postgres-tanzu-operator --for=condition=Available=True postgres-operator

undeploy-postgres-tanzu-operator:
	tanzu package installed delete postgres-tanzu-operator --namespace postgres-tanzu-operator --yes
	#tanzu secret registry delete $(INSTALL_REGISTRY_HOSTNAME)--yes
	tanzu package repository delete tanzu-data-services-repository --namespace postgres-tanzu-operator --yes

postgres-tanzu-operator-helm:
	helm registry login registry.tanzu.vmware.com --username=$(TANZUNET_USER) --password=$(TANZUNET_PASSWORD)
	helm install postgres-operator-chart-$(POSTGRESQL_OPERATION_VERSION) oci://registry.tanzu.vmware.com/tanzu-sql-postgres/postgres-operator-chart --version v$(POSTGRESQL_OPERATION_VERSION)  --namespace=postgres-tanzu-operator --create-namespace 
	kubectl create secret docker-registry regsecret --docker-server https://registry.tanzu.vmware.com/ --docker-username $(TANZUNET_USER) --docker-password $(TANZUNET_PASSWORD) --namespace postgres-tanzu-operator	
	helm status postgres-operator-chart-$(POSTGRESQL_OPERATION_VERSION)  -n postgres-tanzu-operator
	kubectl wait deployment -n postgres-tanzu-operator --for=condition=Available=True postgres-operator

undeploy-postgres-tanzu-operator-helm:
	helm delete postgres-operator-chart-$(POSTGRESQL_OPERATION_VERSION)  -n postgres-tanzu-operator
	kubectl delete ns postgres-tanzu-operator

tekton: namespace
	kapp deploy -c --yes -a tekton -f https://storage.googleapis.com/tekton-releases/pipeline/previous/v0.31.0/release.yaml

deploy-packages: fluxcd contour cnb cert-manager cartographer kapp-controler tekton

undeploy-packages:
	kapp delete --yes -a cartographer 
	kapp delete --yes -a kapp-controler
	kapp delete --yes -a cert-manager
	kapp delete --yes	 -a gitops-toolkit
	kapp delete --yes -a kpack

external-secrets:
	tanzu package install external-secrets   -p external-secrets.apps.tanzu.vmware.com --version  0.6.1+tap.6 -n tap-install
	kapp deploy -a azure-secret-sp -n tap-install -f  ~/.azure/rbac/vault-micropets.yaml

# TODO move this configuration to tanzutips/aks./configure-access-to-azure-secrets.sh aks-eu-tap-5 vault-micropets mytanzu.xyz
#CLUSTER_NAME=aks-eu-tap-5
#KEY_VAULT=bmoussaud-keyvault
#KEY_VAULT_RG=mytanzu.xyz
	