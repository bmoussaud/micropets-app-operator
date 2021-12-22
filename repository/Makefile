MICROPETS_SP_NS=micropets-supplychain
KAPPDIR=../kapp
ENV=env/east-coast-1
VERSION=app/micropet/20221222
OVERRIDE_VALUES=
_DEPLOY="| kapp deploy --yes -a micropet-$@"

deploy-all: deploy-services deploy-front

deploy-services: cats fishes dogs 
deploy-front: pets 

namespace:
	kubectl create namespace $(MICROPETS_SP_NS) --dry-run=client -o yaml | kubectl apply -f -
	kubectl get namespace $(MICROPETS_SP_NS) 

generate:
	@printf "`tput bold`= $@`tput sgr0`\n"
	$(OVERRIDE_VALUES) ytt --ignore-unknown-comments -f $(KAPPDIR)/service -f $(VERSION)/default-schema.yaml -f $(ENV)/default-values.yaml -f $(VERSION)/cats-values.yaml --data-values-env OVERRIDE_WITH


cats: 
	@printf "`tput bold`= Deploy $@`tput sgr0`\n"
	$(OVERRIDE_VALUES) ytt --ignore-unknown-comments -f $(KAPPDIR)/service -f $(VERSION)/default-schema.yaml -f $(ENV)/default-values.yaml -f $(VERSION)/$@-values.yaml --data-values-env OVERRIDE_WITH | kapp deploy --diff-changes --yes --into-ns $(MICROPETS_SP_NS) -a micropet-$@ -f-

dogs: 
	@printf "`tput bold`= Deploy $@`tput sgr0`\n"
	$(OVERRIDE_VALUES) ytt --ignore-unknown-comments -f $(KAPPDIR)/service -f $(VERSION)/default-schema.yaml -f $(ENV)/default-values.yaml -f $(VERSION)/$@-values.yaml --data-values-env OVERRIDE_WITH | kapp deploy --diff-changes --yes --into-ns $(MICROPETS_SP_NS) -a micropet-$@ -f-

fishes: 
	@printf "`tput bold`= Deploy $@`tput sgr0`\n"
	$(OVERRIDE_VALUES) ytt --ignore-unknown-comments -f $(KAPPDIR)/service -f $(VERSION)/default-schema.yaml -f $(ENV)/default-values.yaml -f$(VERSION)/$@-values.yaml --data-values-env OVERRIDE_WITH | kapp deploy --diff-changes --yes --into-ns $(MICROPETS_SP_NS) -a micropet-$@ -f-

pets: 
	@printf "`tput bold`= Deploy $@`tput sgr0`\n"
	$(OVERRIDE_VALUES) ytt --ignore-unknown-comments -f $(KAPPDIR)/service -f $(VERSION)/default-schema.yaml -f $(ENV)/default-values.yaml -f$(VERSION)/$@-values.yaml --data-values-env OVERRIDE_WITH | kapp deploy --diff-changes --yes --into-ns $(MICROPETS_SP_NS) -a micropet-$@ -f-

gui: 
	@printf "`tput bold`= Deploy $@`tput sgr0`\n"
	$(OVERRIDE_VALUES) ytt --ignore-unknown-comments -f $(KAPPDIR)/gui -f $(VERSION)/default-schema.yaml -f $(ENV)/default-values.yaml -f $(VERSION)/$@-values.yaml --data-values-env OVERRIDE_WITH | kapp deploy --diff-changes --yes --into-ns $(MICROPETS_SP_NS) -a micropet-$@ -f-

	
undeploy-services:
	kapp delete -c --yes -a micropet-cats
	kapp delete -c --yes -a micropet-dogs
	kapp delete -c --yes -a micropet-fishes
	
undeploy-front:
	kapp delete -c --yes -a micropet-pets
	kapp delete -c --yes -a micropet-gui

undeploy-all: undeploy-services undeploy-front


vload:	
	vegeta attack -targets=$(ENV)/targets.txt -name=300qps -rate=300 -duration=10s | vegeta plot > plot.300qps.html
	
	

APP := fio
NAMESPACE := kapp
FLAGS := --namespace $(NAMESPACE) --app $(APP) --diff-changes
SHELL := /bin/bash
	
localdeploy: build/ytt/out.yaml
	kapp deploy $(FLAGS) -f build/ytt/out.yaml

build/ytt/cats: $(VERSION)/cats-values.yaml
	@printf "`tput bold`= BUILD GEN $@`tput sgr0`\n"
	mkdir -p $(shell dirname $@)
	ytt --ignore-unknown-comments -f $(KAPPDIR)/service -f $(VERSION)/default-schema.yaml -f $(ENV)/default-values.yaml -f $(VERSION)/cats-values.yaml --data-values-env OVERRIDE_WITH -o build/ytt/cats.cyaml
	

	