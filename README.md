# backstage-demo

## Deploy the gitops operator

```shell
oc apply -f ./argocd/operator.yaml
oc apply -f ./argocd/rbac.yaml
oc apply -f ./argocd/argocd.yaml
oc apply -f ./argocd/argo-root-application.yaml
```

this should be all to setup the demo.
Unfortunately there are some hard coded values that are cluster dependent in the resources created by argo. Some work is still needed in this space.