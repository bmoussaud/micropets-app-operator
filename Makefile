MICROPETS_SP_NS=micropets-supplychain

namespace:
	kubectl create namespace $(MICROPETS_SP_NS) --dry-run=client -o yaml | kubectl apply -f -
	kubectl get namespace $(MICROPETS_SP_NS) 

kpack: namespace		
	ytt --ignore-unknown-comments --data-values-env MICROPETS -f kpack | kapp deploy --yes --dangerous-override-ownership-of-existing-resources --into-ns $(MICROPETS_SP_NS) -a micropet-kpack -f-

supplychain: namespace
	ytt --ignore-unknown-comments -f supplychains/app-operator | kapp deploy --yes --dangerous-override-ownership-of-existing-resources --into-ns $(MICROPETS_SP_NS) -a micropet-supplychain -f-

unsupplychain:
	kapp delete --yes -a micropet-supplychain -n  $(MICROPETS_SP_NS) 

local-kapp:
	ytt --ignore-unknown-comments -f kapp/service -f kapp/values/kapp-local-values.yaml

local-knative:
	ytt --ignore-unknown-comments -f kapp/kservice -f kapp/values/kapp-local-values.yaml

local-gui-kapp:
	ytt --ignore-unknown-comments -f kapp/gui -f kapp/values/kapp-local-values.yaml

deploy-knative-app:
	ytt --ignore-unknown-comments -f kapp/kservice -f kapp/values/kapp-local-values.yaml | kapp deploy --yes --dangerous-override-ownership-of-existing-resources -n  $(MICROPETS_SP_NS) --into-ns $(MICROPETS_SP_NS) -a micropet-local-knative -f-
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
	| kapp deploy --yes -n default -a knative-serving-1.0 -f-
	kubectl --namespace istio-system get service istio-ingressgateway

cnb:
	kapp deploy --yes -a kpack -f https://github.com/pivotal/kpack/releases/download/v0.4.3/release-0.4.3.yaml

fluxcd:
	kubectl create clusterrolebinding gitops-toolkit-admin --clusterrole=cluster-admin --serviceaccount=gitops-toolkit:default
	kubectl create namespace gitops-toolkit
	kapp deploy --yes -a gitops-toolkit --into-ns gitops-toolkit -f https://github.com/fluxcd/source-controller/releases/download/v0.15.4/source-controller.crds.yaml -f https://github.com/fluxcd/source-controller/releases/download/v0.15.4/source-controller.deployment.yaml

cert-manager:
	kapp deploy --yes -a cert-manager -f https://github.com/jetstack/cert-manager/releases/download/v1.6.1/cert-manager.yaml

kapp-controler:
	kubectl create clusterrolebinding kapp-controler-admin --clusterrole=cluster-admin --serviceaccount=micropets-supplychain:default
	kapp deploy --dangerous-override-ownership-of-existing-resources --yes -a kapp-controler -f https://github.com/vmware-tanzu/carvel-kapp-controller/releases/latest/download/release.yml

cartographer: 
	kubectl create namespace cartographer-system
	kapp deploy --yes -a cartographer -f https://github.com/vmware-tanzu/cartographer/releases/latest/download/cartographer.yaml

deploy-packages: fluxcd cnb cert-manager cartographer kapp-controler

undeploy-packages:
	kapp delete --yes -a cartographer 
	kapp delete --yes -a kapp-controler
	kapp delete --yes -a cert-manager
	kapp delete --yes -a gitops-toolkit
	kapp delete --yes -a kpack