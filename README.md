# micropets-app-operator

This repository gathers all the configurations that will be managed by an `app-operator` to provide on top a on an infrastructure-ready kubernetest cluster an application-ready cluster

## Cloud Native Build Pack

Set up the project to use [Cloud Native Buildpack](https://buildpacks.io/) instead of managing Dockerfile to create the image

The project will use [kPack](https://github.com/pivotal/kpack). 
If you're looking for a supported version of [kPack](https://github.com/pivotal/kpack), please look at [Tanzu Build Service by vmware](https://tanzu.vmware.com/build-service)

### Install kPack into the cluster

```
kapp deploy --yes -a kpack \
	-f https://github.com/pivotal/kpack/releases/download/v0.3.1/release-0.3.1.yaml
```

### Configure kPack 

Edit [kpack/kpack_values.yaml](kpack/kpack_valuesvalues.yaml) 
the kpack folder defines the cluster-scoped resources and the shared resources amongs the services

```
export MICROPETS_registry_password="moussaud"
kubectl create ns ${MICROPETS_into_ns}
ytt --ignore-unknown-comments --data-values-env  MICROPETS   -f . | kapp deploy --yes --into-ns ${MICROPETS_into_ns} -a micropet-kpack -f-
```

or

```
MICROPETS_registry_password="moussaud" make kpack
```

### Check the builder is available 

```
$kubectl get ClusterBuilder micropet-builder
NAME               LATESTIMAGE                                                                                                           READY
micropet-builder   harbor.mytanzu.xyz/library/micropet-builder@sha256:dd1993c5a5550f7b91052330d11bb029bd2f108776dff5097e42e813988ae1b9   True
```

in each service project, the `kpack.yaml` file specify what to build (Image). 
Run `make deploy-cnb` to apply the definition using the current kubernetes context (at the root of the project or individually)

_undeploy everything_

kapp delete -a micropet-kpack
kubectl delete  ns ${MICROPETS_into_ns}

## Supply Chains

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
    - name: observability
      value: true   
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

### install cartographer

Source : https://cartographer.sh/docs/install/ 
v0.0.7

````
kubectl create namespace cartographer-system
kubectl apply -f https://github.com/vmware-tanzu/cartographer/releases/latest/download/cartographer.yaml
````

### install the micropet Supply Chains

````
❯ make tap
kubectl create namespace "micropets-supplychain" --dry-run=client -o yaml | kubectl apply -f -
namespace/micropets-supplychain configured
kubectl get namespace "micropets-supplychain"
NAME                    STATUS   AGE
micropets-supplychain   Active   58d
ytt --ignore-unknown-comments -f tap/app-operator | kapp deploy --yes --dangerous-override-ownership-of-existing-resources --into-ns "micropets-supplychain" -a micropet-tap -f-
Target cluster 'https://gimckc2x2x1ar31iv6sd8124v6od-k8s-312336063.eu-west-3.elb.amazonaws.com:443' (nodes: ip-10-0-1-199.eu-west-3.compute.internal, 3+)

Changes

Namespace  Name                               Kind                Conds.  Age  Op      Op st.  Wait to    Rs  Ri
(cluster)  micropet-gui-service-supply-chain  ClusterSupplyChain  -       -    create  -       reconcile  -   -
^          micropet-service-supply-chain      ClusterSupplyChain  -       -    create  -       reconcile  -   -

Op:      2 create, 0 delete, 0 update, 0 noop
Wait to: 2 reconcile, 0 delete, 0 noop

4:44:06PM: ---- applying 2 changes [0/2 done] ----
4:44:07PM: create clustersupplychain/micropet-gui-service-supply-chain (carto.run/v1alpha1) cluster
4:44:07PM: create clustersupplychain/micropet-service-supply-chain (carto.run/v1alpha1) cluster
4:44:07PM: ---- waiting on 2 changes [0/2 done] ----
4:44:07PM: ok: reconcile clustersupplychain/micropet-service-supply-chain (carto.run/v1alpha1) cluster
4:44:07PM: ok: reconcile clustersupplychain/micropet-gui-service-supply-chain (carto.run/v1alpha1) cluster
4:44:07PM: ---- applying complete [2/2 done] ----
4:44:07PM: ---- waiting complete [2/2 done] ----

Succeeded
````


## Cloud Native Runtime / KNative

### Core
````
kapp deploy -n default -a knative-serving-1.0 -f https://github.com/knative/serving/releases/download/knative-v1.0.0/serving-crds.yaml -f https://github.com/knative/serving/releases/download/knative-v1.0.0/serving-core.yaml
````
Ref: https://knative.dev/docs/install/serving/install-serving-with-yaml/

### Istio 
If `Istio` hasn't been [installed](https://istio.io/latest/docs/setup/getting-started/#download)
````
$kubectl create ns istio-system
$istioctl install --set profile=default -y
➜ istioctl install --set profile=default -y
✔ Istio core installed
✔ Istiod installed
✔ Ingress gateways installed
✔ Installation complete
````

### Configure DNS

Ref: https://knative.dev/docs/install/serving/install-serving-with-yaml/#configure-dns

Fetch the External IP address or CNAME by running the command:
````
➜ kubectl --namespace istio-system get service istio-ingressgateway

NAME                   TYPE           CLUSTER-IP       EXTERNAL-IP                                                               PORT(S)                                      AGE
istio-ingressgateway   LoadBalancer   10.101.243.102   a5ea5edbenoita79cbed84ee388a-1045033682.eu-west-3.elb.amazonaws.com   15021:30542/TCP,80:31378/TCP,443:30205/TCP   3m28s
````

`*.cnr.mytanzu.xyz` and `cnr.mytanzu.xyz` defined in AWS
![screen](img/configure-dns-record-aws.png)

Put this value in [knative/values.yaml](knative/values.yaml)


### Deploy Knative / Istio 

The following command deploy __knative 1.0.0__ with the istio configuration.
Moreover, with ytt, it overlays the configuration to configure the `k-services` to
* to use a custom domain name (here cnr.mytanzu.xyz)
* to use be exposed using either the default configuration ({{.Name}}-{{.Namespace}}.{{.Domain}}) or by reading the `service.subdomain` annotation set on the service.

````
ytt --ignore-unknown-comments -f knative \
		-f https://github.com/knative/serving/releases/download/knative-v1.0.0/serving-crds.yaml  \
		-f https://github.com/knative/serving/releases/download/knative-v1.0.0/serving-core.yaml  \
		-f https://github.com/knative/net-istio/releases/download/knative-v1.0.0/net-istio.yaml   \
	| kapp deploy --yes -n default -a knative-serving-1.0 -f-
	kubectl --namespace istio-system get service istio-ingressgateway
````

Check the configuration using :

````
kubectl get cm  -n knative-serving config-network  -o yaml
kubectl get cm  -n knative-serving config-domain  -o yaml
````
