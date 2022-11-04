make tanzu-cluster-essentials

make tap
watch kubectl get app -A
make tap-gui-ip
tanzu acc create micropets-java-service-accelerator --git-repo https://github.com/bmoussaud/micropet-java-service-accelerator --git-branch main --interval 5s
tanzu acc create micropets-golang-service-accelerator --git-repo https://github.com/bmoussaud/micropets-golang-service-accelerator --git-branch main --interval 5s

make postgres-tanzu-operator