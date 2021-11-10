# micropets-app-operator

With a `ClusterSupplyChain`, the app operators describe which "shape of applications" they deal with (via `spec.selector`), and what series of components are responsible for creating an artifact that delivers it (via `spec.components`).

Those `Workload`s that match `spec.selector` then go through the components specified in `spec.components`.

The `micropet-service-supply-chain` supplychain manages the backend services : dogs, cats, fishes and pets.

![micropet-service-supply-chain](img/tap/micropet-service-supply-chain.jpg)

it includes
1. Watch a repository using `fluxcd/GitRepository`
1. Build a new image using `kpack/Image`
1. Configure the application using `kubernetes/ConfigMap`
1. Trigger a deployment using `kapp-controler/kapp` 

All theses 4 resources are described in [supply-chain-templates.yaml](cluster/tap/app-operator/supply-chain-templates.yaml) and put together in [supply-chain.yaml](cluster/tap/app-operator/supply-chain.yaml)

Then each service must provide a new workload based on this supply chain. 

The association between a workload and the requested supplychain is based using labels: 
`app.tanzu.vmware.com/workload-type`.



Example: request A new workload called `micropet-service` with the following git repository using the `RANDOM_NUMBER` mode and listening on the `7003` port.

````
apiVersion: carto.run/v1alpha1
kind: Workload
metadata:
  name: dogs
  labels:
    app.tanzu.vmware.com/workload-type: micropet-service
spec:
  source:
    git:
      url: https://github.com/bmoussaud/micropets-app/
      ref:
        branch: master      
  params:
    - name: mode
      value: "RANDOM_NUMBER"
    - name: port
      value: 7003   
````

apply this yaml definition and wacth

````
kubectl tree Workload dogs -n micropets-supplychain
Every 2,0s: kubectl tree Workload dogs -n micropets-supplychain                                                                           bmoussaud-a02.vmware.com: Fri Oct  1 16:02:08 2021

NAMESPACE              NAME                                             READY    REASON        AGE
micropets-supplychain  Workload/dogs                                    True     Ready         75s
micropets-supplychain  ├─App/dogs-application                           -                      25s
micropets-supplychain  ├─ConfigMap/micropet-service-dogs-config         -                      25s
micropets-supplychain  ├─GitRepository/micropet-dogs                    Unknown  Progressing   75s
micropets-supplychain  └─Image/micropet-dogs                            True                   70s
micropets-supplychain    ├─Build/micropet-dogs-build-1-tw6vt            -                      70s
micropets-supplychain    │ └─Pod/micropet-dogs-build-1-tw6vt-build-pod  False    PodCompleted  69s
micropets-supplychain    ├─PersistentVolumeClaim/micropet-dogs-cache    -                      70s
micropets-supplychain    └─SourceResolver/micropet-dogs-source          True                   70s

````

Several resources (kpack image, kapp-controler app, kubernetes config map, fluxcd git repository) are created and connected all together by the workload.

