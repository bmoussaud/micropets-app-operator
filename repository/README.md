
## All components in both clusters

* on Europ2
````bash
KAPP_KUBECONFIG_CONTEXT=bmoussaud-aws-europ2-admin@bmoussaud-aws-europ2 make clean deploy-all ENV=env/europ2 OVERRIDE_VALUES=OVERRIDE_WITH_environment__domain__internal=.bmoussaud.prod
````
* on Aks-East-Coast-1
```bash
KAPP_KUBECONFIG_CONTEXT=aks-east-coast-1 make clean deploy-all ENV=env/east-coast-1 OVERRIDE_VALUES=OVERRIDE_WITH_environment__domain__internal=.bmoussaud.prod
````


## Split
* Backend services on Europ2
```bash
KAPP_KUBECONFIG_CONTEXT=bmoussaud-aws-europ2-admin@bmoussaud-aws-europ2 make clean deploy-services ENV=env/europ2 OVERRIDE_VALUES=OVERRIDE_WITH_environment__domain__internal=.bmoussaud.prod
```

* Fronted services on Aks-East-Coast-1
```bash
KAPP_KUBECONFIG_CONTEXT=aks-east-coast-1 make clean deploy-front ENV=env/east-coast-1 OVERRIDE_VALUES=OVERRIDE_WITH_environment__domain__internal=.bmoussaud.prod
```

## other

kctx aws-europe-2
make deploy-services ENV=env/europ2 OVERRIDE_VALUES=OVERRIDE_WITH_environment__domain__internal=.bmoussaud.prod
make deploy-front ENV=env/europ2 OVERRIDE_VALUES=OVERRIDE_WITH_environment__domain__internal=.bmoussaud.prod
make vload ENV=env/europ2

kctx aks-east-coast-1
make namespace deploy-front ENV=env/east-coast-1 OVERRIDE_VALUES=OVERRIDE_WITH_environment__domain__internal=.bmoussaud.prod
make vload ENV=env/east-coast-1


kubectx c1-admin@c1
make namespace deploy-services ENV=env/c1 OVERRIDE_VALUES=OVERRIDE_WITH_environment__domain__internal=.bmoussaud.prod


k delete ns micropets-supplychain --context aks-east-coast-1
k delete ns micropets-supplychain --context bmoussaud-aws-europ2-admin@bmoussaud-aws-europ2
k delete ns micropets-supplychain --context c1-admin@c1


## Manual Deploy

```
make clean generate-cats generate-dogs generate-fishes ENV=env/east-coast-1 OVERRIDE_VALUES=OVERRIDE_WITH_environment__domain__internal=.bmoussaud.prod 
kubectl apply --context aks-east-coast-1  -n micropets-supplychain -f env/east-coast-1/generated/cats -f env/east-coast-1/generated/dogs  -f env/east-coast-1/generated/fishes 

make clean generate-pets ENV=env/east-coast-1 OVERRIDE_VALUES=OVERRIDE_WITH_environment__domain__internal=.bmoussaud.prod 
kubectl apply --context aks-east-coast-1  -n micropets-supplychain -f env/east-coast-1/generated/pets
curl http://east1.mytanzu.xyz/pets
```

```
make clean generate-cats generate-dogs generate-fishes ENV=env/europ2 OVERRIDE_VALUES=OVERRIDE_WITH_environment__domain__internal=.bmoussaud.prod 
kubectl apply --context bmoussaud-aws-europ2-admin@bmoussaud-aws-europ2 -n micropets-supplychain -f env/europ2/generated/cats -f env/europ2/generated/dogs  -f env/europ2/generated/fishes 
curl http://micropet.europ2.mytanzu.xyz/fishes/v1/data
```



## links

https://github.com/vmware-tanzu/projects-operator/blob/master/scripts/kapp-deploy
