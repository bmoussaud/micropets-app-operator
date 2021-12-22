
make generate OVERRIDE_VALUES=OVERRIDE_WITH_environment__domain__internal=.bmoussaud.prod


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
k delete ns micropets-supplychain --context aws-europe-2
k delete ns micropets-supplychain --context c1-admin@c1


## Manual Deploy

```
kctx aks-east-coast-1
rm aks-east-coast-1.yaml
make pets gui ENV=env/east-coast-1 OVERRIDE_VALUES=OVERRIDE_WITH_environment__domain__internal=.bmoussaud.prod DEPLOY=">> aks-east-coast-1.yaml && echo '---' >> aks-east-coast-1.yaml"
kubectl apply -f aks-east-coast-1.yaml -n micropets-supplychain
curl http://east1.mytanzu.xyz/pets
```

```
kctx aws-europe-2
rm europ2.yaml
make cats dogs fishes ENV=env/europ2 OVERRIDE_VALUES=OVERRIDE_WITH_environment__domain__internal=.bmoussaud.prod DEPLOY=">> europ2.yaml && echo '---' >> europ2.yaml"
kubectl apply -f europ2.yaml -n micropets-supplychain
curl http://europ2.mytanzu.xyz/pets
```

```
kctx aws-europe-2
rm europ2-pets.yaml
make pets ENV=env/europ2 OVERRIDE_VALUES=OVERRIDE_WITH_environment__domain__internal=.bmoussaud.prod DEPLOY=">> europ2-pets.yaml"
kubectl apply -f europ2-pets.yaml -n micropets-supplychain
curl http://europ2.mytanzu.xyz/pets
```


## links

https://github.com/vmware-tanzu/projects-operator/blob/master/scripts/kapp-deploy
