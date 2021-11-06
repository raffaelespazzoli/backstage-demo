# backstage-demo

## Deploy the gitops operator

```shell
oc apply -f ./argocd/operator.yaml
```

apply the root argo application

```shell
oc apply -f ./argo-root-application.yaml
```


## Deploy gitlab operator

```shell
GL_OPERATOR_VERSION=0.1.0
PLATFORM=openshift
oc create namespace gitlab-system
oc apply -f ./gitlab/gitlab.yaml
```

helm based approach

```shell
oc new-project gitlab-system
oc adm policy add-scc-to-user nonroot -z gitlab-shared-secrets -n gitlab-system
oc adm policy add-scc-to-user nonroot -z default -n gitlab-system
oc adm policy add-scc-to-user nonroot -z gitlab-prometheus-server -n gitlab-system
oc adm policy add-scc-to-user nonroot -z gitlab-gitlab-runner -n gitlab-system
oc adm policy add-scc-to-user nonroot -z gitlab-certmanager-issuer -n gitlab-system
helm repo add gitlab https://charts.gitlab.io/
export cluster_base_domain=$(oc get dns cluster -o jsonpath='{.spec.baseDomain}')

oc apply -f ./gitlab/credentials-request.yaml
envsubst < ./gitlab/values.yaml > /tmp/values.yaml
helm upgrade gitlab gitlab/gitlab -i --create-namespace --namespace gitlab-system -f /tmp/values.yaml
export AWS_ACCESS_KEY_ID=$(oc get secret cert-manager-dns-credentials -n gitlab-system -o jsonpath='{.data.aws_access_key_id}' | base64 -d)
export REGION=$(oc get nodes --template='{{ with $i := index .items 0 }}{{ index $i.metadata.labels "failure-domain.beta.kubernetes.io/region" }}{{ end }}')
export zoneid=$(oc get dns cluster -o jsonpath='{.spec.publicZone.id}')
export EMAIL=raffaele.spazzoli@gmail.com
envsubst < ./gitlab/routes.yaml | oc apply -f - -n gitlab-system
```