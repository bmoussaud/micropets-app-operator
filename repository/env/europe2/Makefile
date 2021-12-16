MICROPETS_SP_NS=micropets-supplychain
KAPPDIR=../../kapp

deploy-all: cats fishes dogs pets gui

namespace:
	kubectl create namespace $(MICROPETS_SP_NS) --dry-run=client -o yaml | kubectl apply -f -
	kubectl get namespace $(MICROPETS_SP_NS) 

generate:
	@printf "`tput bold`= $@`tput sgr0`\n"
	ytt --ignore-unknown-comments -f $(KAPPDIR)/service -f default-schema.yaml -f default-values.yaml -f cats-values.yaml 

cats: namespace
	@printf "`tput bold`= Deploy $@`tput sgr0`\n"
	ytt --ignore-unknown-comments -f $(KAPPDIR)/service -f default-schema.yaml -f default-values.yaml -f $@-values.yaml | kapp deploy --yes --into-ns $(MICROPETS_SP_NS) -a micropet-$@ -f-

dogs: namespace
	@printf "`tput bold`= Deploy $@`tput sgr0`\n"
	ytt --ignore-unknown-comments -f $(KAPPDIR)/service -f default-schema.yaml -f default-values.yaml -f $@-values.yaml | kapp deploy --yes --into-ns $(MICROPETS_SP_NS) -a micropet-$@ -f-

fishes: namespace
	@printf "`tput bold`= Deploy $@`tput sgr0`\n"
	ytt --ignore-unknown-comments -f $(KAPPDIR)/service -f default-schema.yaml -f default-values.yaml -f $@-values.yaml | kapp deploy --yes --into-ns $(MICROPETS_SP_NS) -a micropet-$@ -f-

pets: namespace
	@printf "`tput bold`= Deploy $@`tput sgr0`\n"
	ytt --ignore-unknown-comments -f $(KAPPDIR)/service -f default-schema.yaml -f default-values.yaml -f $@-values.yaml | kapp deploy --yes --into-ns $(MICROPETS_SP_NS) -a micropet-$@ -f-

gui: namespace
	@printf "`tput bold`= Deploy $@`tput sgr0`\n"
	ytt --ignore-unknown-comments -f $(KAPPDIR)/gui -f default-schema.yaml -f default-values.yaml -f $@-values.yaml | kapp deploy --yes --into-ns $(MICROPETS_SP_NS) -a micropet-$@ -f-
	
undeploy-all:
	kapp delete --yes -a micropet-cats
	kapp delete --yes -a micropet-dogs
	kapp delete --yes -a micropet-pets
	kapp delete --yes -a micropet-fishes
	kapp delete --yes -a micropet-gui

load:
	vegeta attack -targets=targets.txt -name=300qps -rate=300 -duration=10s | vegeta plot > plot.300qps.html
	
	
