MICROPETS_SP_NS=micropets-supplychain
KAPPDIR=../kapp
ENV=env/east-coast-1
VERSION=app/micropet/20221222
OVERRIDE_VALUES=

KAPP_FLAGS:= --diff-changes --yes --into-ns $(MICROPETS_SP_NS)

deploy-all: deploy-services deploy-front
deploy-services: deploy-cats deploy-fishes deploy-dogs 
deploy-front: deploy-pets deploy-gui

clean:
	-rm -rf $(ENV)/generated

namespace:
	kubectl create namespace $(MICROPETS_SP_NS) --dry-run=client -o yaml | kubectl apply -f -
	kubectl get namespace $(MICROPETS_SP_NS) 

generate:
	@printf "`tput bold`= $@`tput sgr0`\n"
	$(OVERRIDE_VALUES) ytt --ignore-unknown-comments -f $(KAPPDIR)/service -f $(VERSION)/default-schema.yaml -f $(ENV)/default-values.yaml -f $(VERSION)/cats-values.yaml --data-values-env OVERRIDE_WITH

deploy-%: $(ENV)/generated/%/resources.yaml	
	@printf "`tput bold`= Deploy $@ (micropet-$*) `tput sgr0`\n"
	kapp deploy $(KAPP_FLAGS) -a micropet-$* -f $<

generate-%: $(ENV)/generated/%/resources.yaml	
	
.PRECIOUS: $(ENV)/generated/gui/resources.yaml
$(ENV)/generated/gui/resources.yaml: $(VERSION)/gui-values.yaml
	@printf "`tput bold`= Generate $@`tput sgr0`\n"
	$(OVERRIDE_VALUES) ytt --ignore-unknown-comments -f $(KAPPDIR)/gui -f $(VERSION)/default-schema.yaml -f $(ENV)/default-values.yaml -f $< --data-values-env OVERRIDE_WITH --output-files $@

.PRECIOUS: $(ENV)/generated/%/resources.yaml
$(ENV)/generated/%/resources.yaml: $(VERSION)/%-values.yaml
	@printf "`tput bold`= Generate $@`tput sgr0`\n"
	$(OVERRIDE_VALUES) ytt --ignore-unknown-comments -f $(KAPPDIR)/service -f $(VERSION)/default-schema.yaml -f $(ENV)/default-values.yaml -f $< --data-values-env OVERRIDE_WITH --output-files $@

undeploy-services:
	kapp delete -c --yes -a micropet-cats
	kapp delete -c --yes -a micropet-dogs
	kapp delete -c --yes -a micropet-fishes
	
undeploy-front:
	kapp delete -c --yes -a micropet-pets
	kapp delete -c --yes -a micropet-gui

undeploy-all: undeploy-services undeploy-front

deliverables:	
	$(OVERRIDE_VALUES) ytt --ignore-unknown-comments -f $(ENV)/deliverables | kapp deploy -c --yes -a deliverables-`echo $(ENV) | sed "s/\//-/g"` --into-ns $(MICROPETS_SP_NS)  -f-

undeliverables:	
	kapp delete --yes -a deliverables-`echo $(ENV) | sed "s/\//-/g"` 


vload:	
	vegeta attack -targets=$(ENV)/targets.txt -name=100qps -rate=100 -duration=10s | vegeta plot > $(ENV)/vegeta.html
	
	
	