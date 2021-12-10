MICROPETS_SP_NS=micropets-europe2
KAPPDIR=../../kapp

all: cats fishes dogs pets gui

namespace:
	kubectl create namespace $(MICROPETS_SP_NS) --dry-run=client -o yaml | kubectl apply -f -
	kubectl get namespace $(MICROPETS_SP_NS) 

cats: namespace
	@printf "`tput bold`= $@`tput sgr0`\n"
	ytt --ignore-unknown-comments -f =$(KAPPDIR)/service -f cats-values.yaml | kapp deploy --yes --into-ns $(MICROPETS_SP_NS) -a micropet-cats -f-

dogs: namespace
	@printf "`tput bold`= $@`tput sgr0`\n"
	ytt --ignore-unknown-comments -f =$(KAPPDIR)/service -f dogs-values.yaml | kapp deploy --yes --into-ns $(MICROPETS_SP_NS) -a micropet-dogs -f-

fishes: namespace
	@printf "`tput bold`= $@`tput sgr0`\n"
	ytt --ignore-unknown-comments -f =$(KAPPDIR)/service -f fishes-values.yaml | kapp deploy --yes --into-ns $(MICROPETS_SP_NS) -a micropet-fishes -f-

pets: namespace
	@printf "`tput bold`= $@`tput sgr0`\n"
	ytt --ignore-unknown-comments -f =$(KAPPDIR)/service -f pets-values.yaml | kapp deploy --yes --into-ns $(MICROPETS_SP_NS) -a micropet-pets -f-

gui: namespace
	@printf "`tput bold`= $@`tput sgr0`\n"
	ytt --ignore-unknown-comments -f =$(KAPPDIR)/gui -f gui-values.yaml | kapp deploy --yes --into-ns $(MICROPETS_SP_NS) -a micropet-gui -f-


load:
	vegeta attack -targets=targets.txt -name=300qps -rate=300 -duration=10s | vegeta plot > plot.300qps.html
	
	
