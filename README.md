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


notes

https://gitlab-configuration-as-code.readthedocs.io/en/latest/faq.html
https://github.com/crossplane-contrib/provider-gitlab

oc new-project github-cicd
oc adm policy add-cluster-role-to-user cluster-admin -z default -n github-cicd
oc serviceaccounts get-token default -n github-cicd


kube svc account for backstage

```shell
oc create serviceaccount backstage -n default
oc adm policy add-cluster-role-to-user cluster-reader -z backstage -n default
oc serviceaccounts get-token backstage -n default
```

create github secret for ocp

cretae github oauth app at the rog level

```shell
source secret.sh
oc create secret generic ocp-github-app-credentials --from-literal=client_id=${ocp_github_client_id} --from-literal=clientSecret=${ocp_github_client_secret} -n openshift-config
```
