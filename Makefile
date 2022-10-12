MICROPETS_SP_NS=dev-tap
SECRET_OUTPUT_FILE=.secrets.yaml

namespace:
	kubectl create namespace $(MICROPETS_SP_NS) --dry-run=client -o yaml | kubectl apply -f -
	kubectl get namespace $(MICROPETS_SP_NS) 

kpack: namespace		
	ytt --ignore-unknown-comments --data-values-env MICROPETS -f kpack | kapp deploy -c --yes  --into-ns $(MICROPETS_SP_NS) -a micropet-kpack -f-

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
	kapp deploy -c --yes --dangerous-override-ownership-of-existing-resources -a kapp-controler -f https://github.com/vmware-tanzu/carvel-kapp-controller/releases/download/v0.34.0/release.yml

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
	az provider register --namespace  Microsoft.DBforPostgreSQL

aso-core:
	kubectl apply --server-side=true -f azure-service-operator/aso_azureserviceoperator_v2.0.0-beta.2.yaml
	kubectl apply --server-side=true -f azure-service-operator/aso_mutating_webhook.yaml
	kubectl apply --server-side=true -f azure-service-operator/aso_validating_webhook.yaml
	kubectl apply --server-side=true -f azure-service-operator/aso_crd.yaml

undeploy-aso-core:
	kubectl delete  -f azure-service-operator/aso_azureserviceoperator_v2.0.0-beta.2.yaml
	kubectl delete  -f azure-service-operator/aso_mutating_webhook.yaml
	kubectl delete  -f azure-service-operator/aso_validating_webhook.yaml
	kubectl delete  -f azure-service-operator/aso_crd.yaml

aso: 
	source ~/.azure/rbac/azure-service-operator-contributor-aks-eu-tap-2.config \
		&& ytt --ignore-unknown-comments --data-values-env AZURE \
		-f azure-service-operator/secrets.yaml  | kapp deploy -a aso-secrets --yes -c -f-		

	kubectl wait deployment -n azureserviceoperator-system -l app=azure-service-operator-v2 --for=condition=Available=True

aso-test:
	ytt -f azure-service-operator-instance  --ignore-unknown-comments | kapp deploy -c --yes -a aso-test -f-
	kubectl tree resourcegroups.resources.azure.com -n asodemo aso-demo-rg-1

undeploy-aso: undeploy-aso-core
	kubectl delete -f https://github.com/Azure/azure-service-operator/releases/download/v2.0.0-beta.2/azureserviceoperator_v2.0.0-beta.2.yaml

undeploy-aso-test:
	kapp delete -a aso-test --yes
	ytt -f azure-service-operator-instance  --ignore-unknown-comments | kubectl delete -f-


POSTGRESQL_OPERATION_VERSION=1.9.0
postgres-tanzu-operator:
	helm registry login registry.tanzu.vmware.com --username=$(TANZUNET_USER) --password=$(TANZUNET_PASSWORD)
	helm install postgres-operator-chart-$(POSTGRESQL_OPERATION_VERSION) oci://registry.tanzu.vmware.com/tanzu-sql-postgres/postgres-operator-chart --version v$(POSTGRESQL_OPERATION_VERSION)  --namespace=postgres-tanzu-operator --create-namespace 
	kubectl create secret docker-registry regsecret --docker-server https://registry.tanzu.vmware.com/ --docker-username $(TANZUNET_USER) --docker-password $(TANZUNET_PASSWORD) --namespace postgres-tanzu-operator	
	helm status postgres-operator-chart-$(POSTGRESQL_OPERATION_VERSION)  -n postgres-tanzu-operator
	kubectl wait deployment -n postgres-tanzu-operator --for=condition=Available=True postgres-operator

undeploy-postgres-tanzu-operator:
	helm delete postgres-operator-chart-$(POSTGRESQL_OPERATION_VERSION)  -n postgres-tanzu-operator
	kubectl delete ns postgres-tanzu-operator

tekton: namespace
	kapp deploy -c --yes -a tekton -f https://storage.googleapis.com/tekton-releases/pipeline/previous/v0.31.0/release.yaml

deploy-packages: fluxcd contour cnb cert-manager cartographer kapp-controler tekton

undeploy-packages:
	kapp delete --yes -a cartographer 
	kapp delete --yes -a kapp-controler
	kapp delete --yes -a cert-manager
	kapp delete --yes -a gitops-toolkit
	kapp delete --yes -a kpack

