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


oc adm policy add-scc-to-user nonroot -z gitlab-shared-secrets -n gitlab-system
oc adm policy add-scc-to-user nonroot -z default -n gitlab-system
oc adm policy add-scc-to-user nonroot -z gitlab-prometheus-server -n gitlab-system
oc adm policy add-scc-to-user nonroot -z gitlab-gitlab-runner -n gitlab-system
oc adm policy add-scc-to-user nonroot -z gitlab-certmanager-issuer -n gitlab-system