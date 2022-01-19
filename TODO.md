
### TODO

on AKS Connection reset / refused when downloading the content, so switch to git
```
        - http:
            url: $(deployment.url)$     
```


```
status:
  conditions:
  - message: 'Fetching resources: Error (see .status.usefulErrorMessage for details)'
    status: "True"
    type: ReconcileFailed
  consecutiveReconcileFailures: 1
  fetch:
    error: 'Fetching resources: Error (see .status.usefulErrorMessage for details)'
    exitCode: 1
    startedAt: "2022-01-19T09:50:56Z"
    stderr: |
      vendir: Error: Syncing directory '1':
        Syncing directory '.' with HTTP contents:
          Downloading URL:
            Initiating URL download:
              Get "http://source-controller.gitops-toolkit.svc.cluster.local./gitrepository/micropets-supplychain/gui/11bee0111c9069066c7f165d4f821be3b95c7bc1.tar.gz": read tcp 10.244.2.61:59936->10.0.42.79:80: read: connection reset by peer
    updatedAt: "2022-01-19T09:50:57Z"
  friendlyDescription: 'Reconcile failed: Fetching resources: Error (see .status.usefulErrorMessage
    for details)'
  observedGeneration: 1
  usefulErrorMessage: |
    vendir: Error: Syncing directory '1':
      Syncing directory '.' with HTTP contents:
        Downloading URL:
          Initiating URL download:
            Get "http://source-controller.gitops-toolkit.svc.cluster.local./gitrepository/micropets-supplychain/gui/11bee0111c9069066c7f165d4f821be3b95c7bc1.tar.gz": read tcp 10.244.2.61:59936->10.0.42.79:80: read: connection reset by peer
```
