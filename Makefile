MICROPETS_SP_NS=micropets-supplychain

namespace:
	kubectl create namespace $(MICROPETS_SP_NS) --dry-run=client -o yaml | kubectl apply -f -
	kubectl get namespace $(MICROPETS_SP_NS) 

kpack: namespace		
	ytt --ignore-unknown-comments --data-values-env MICROPETS -f kpack | kapp deploy --yes --dangerous-override-ownership-of-existing-resources --into-ns $(MICROPETS_SP_NS) -a micropet-kpack -f-

tap: namespace
	ytt --ignore-unknown-comments -f tap/app-operator | kapp deploy --yes --dangerous-override-ownership-of-existing-resources --into-ns $(MICROPETS_SP_NS) -a micropet-tap -f-

untap:
	kapp delete --yes -a micropet-tap -n  $(MICROPETS_SP_NS) 

local-kapp:
	ytt --ignore-unknown-comments -f tap/kapp -f tap/kapp-values/kapp-local-values.yaml

local-knative:
	ytt --ignore-unknown-comments -f tap/knative -f tap/kapp-values/kapp-local-values.yaml

deploy-knative-app:
	ytt --ignore-unknown-comments -f tap/knative -f tap/kapp-values/kapp-local-values.yaml | kapp deploy --yes --dangerous-override-ownership-of-existing-resources -n  $(MICROPETS_SP_NS) --into-ns $(MICROPETS_SP_NS) -a micropet-local-knative -f-
	kubectl get ksvc dogs-kservice

undeploy-knative-app:
	kapp  delete --yes -a micropet-local-knative -n  $(MICROPETS_SP_NS) 

local-gui-kapp:
	ytt --ignore-unknown-comments -f tap/kapp-gui -f tap/kapp-values/kapp-local-values.yaml

kapp-controler:
	kubectl apply -f kapp-sample.yaml

unkapp-controler:
	kubectl delete -f kapp-sample.yaml

deploy-knative:
	ytt --ignore-unknown-comments -f knative \
			-f https://github.com/knative/serving/releases/download/knative-v1.0.0/serving-crds.yaml  \
			-f https://github.com/knative/serving/releases/download/knative-v1.0.0/serving-core.yaml  \
		-f https://github.com/knative/net-istio/releases/download/knative-v1.0.0/net-istio.yaml   \
	| kapp deploy --yes -n default -a knative-serving-1.0 -f-
	kubectl --namespace istio-system get service istio-ingressgateway
