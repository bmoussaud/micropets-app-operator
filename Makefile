MICROPETS_SP_NS=micropets-supplychain
SECRET_OUTPUT_FILE=.secrets.yaml

namespace:
	kubectl create namespace $(MICROPETS_SP_NS) --dry-run=client -o yaml | kubectl apply -f -
	kubectl get namespace $(MICROPETS_SP_NS) 

kpack: namespace		
	ytt --ignore-unknown-comments --data-values-env MICROPETS -f kpack | kapp deploy -c --yes --dangerous-override-ownership-of-existing-resources --into-ns $(MICROPETS_SP_NS) -a micropet-kpack -f-

supplychain: gen_secrets
	ytt --ignore-unknown-comments -f supplychains --data-values-file $(SECRET_OUTPUT_FILE) | kapp deploy -c --yes --dangerous-override-ownership-of-existing-resources --into-ns $(MICROPETS_SP_NS) -a micropet-supplychain -f-
	-rm $(SECRET_OUTPUT_FILE)

.PHONY: delivery
delivery: gen_secrets	
	ytt --ignore-unknown-comments -f delivery --data-values-file $(SECRET_OUTPUT_FILE) | kapp deploy -c --yes --dangerous-override-ownership-of-existing-resources --into-ns $(MICROPETS_SP_NS) -a micropet-delivery -f-
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

local-gui-kapp:
	ytt --ignore-unknown-comments -f kapp/gui -f kapp/values/kapp-local-values.yaml

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
	kapp deploy -c --yes -a kpack -f https://github.com/pivotal/kpack/releases/download/v0.4.3/release-0.4.3.yaml

fluxcd:
	kubectl create clusterrolebinding gitops-toolkit-admin --clusterrole=cluster-admin --serviceaccount=gitops-toolkit:default
	kubectl create namespace gitops-toolkit
	kapp deploy -c --yes -a gitops-toolkit --into-ns gitops-toolkit -f https://github.com/fluxcd/source-controller/releases/download/v0.15.4/source-controller.crds.yaml -f https://github.com/fluxcd/source-controller/releases/download/v0.15.4/source-controller.deployment.yaml

cert-manager:
	kapp deploy -c --yes -a cert-manager -f https://github.com/jetstack/cert-manager/releases/download/v1.6.1/cert-manager.yaml

kapp-controler:
	kubectl create clusterrolebinding kapp-controler-admin --clusterrole=cluster-admin --serviceaccount=micropets-supplychain:default
	kapp deploy -c --dangerous-override-ownership-of-existing-resources --yes -a kapp-controler -f https://github.com/vmware-tanzu/carvel-kapp-controller/releases/download/v0.31.0/release.yml

contour:
	kapp deploy -c -a contour -f https://projectcontour.io/quickstart/contour.yaml
	
cartographer: cert-manager
	kubectl create namespace cartographer-system --dry-run=client -o yaml | kubectl apply -f -
	kapp deploy -c --yes -a cartographer  -f https://github.com/vmware-tanzu/cartographer/releases/download/v0.1.0/cartographer.yaml

tekton:
	kapp deploy -c --yes -a tekton -f https://storage.googleapis.com/tekton-releases/pipeline/previous/v0.31.0/release.yaml
	kapp deploy -c --into-ns $(MICROPETS_SP_NS) --yes -a tekton-git-cli -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/git-cli/0.2/git-cli.yaml

deploy-packages: fluxcd cnb cert-manager cartographer kapp-controler

undeploy-packages:
	kapp delete --yes -a cartographer 
	kapp delete --yes -a kapp-controler
	kapp delete --yes -a cert-manager
	kapp delete --yes -a gitops-toolkit
	kapp delete --yes -a kpack

