# backstage-demo

This demo is based on GitHub. It requires some manual preparation steps for tasks that do not seem automate-able on GitHub (at least i was no able to automate them).

## Manual preparation

1. create a new organization or reuse an existing one.
2. create an Oauth app in this organization for backstage. The call back url should be `https://backstage-backend.apps.${based_domain}`
3. create an Oauth app in this organization for Code Ready Workspaces. The call back url should be `https://codeready-openshift-workspaces.apps.${based_domain}/auth/realms/codeready/broker/github/endpoint`
4. create an Oauth app in this organization for OpenShift. The call back url should be `https://oauth-openshift.apps.${based_domain}/oauth2callback/backstage-demo-github/`
5. create a Personal Access Token (PAT) with an account that is administrator to the chosen organization.

Create a client secret for each of these apps.

Create a file called `secrets.sh` and store it at the top of this repo, it will be ignored by Git.

```shell
export github_organization=<org_name>
export backstage_github_client_id=<backstage_oauth_app_id>
export backstage_github_client_secret=<backstage_oauth_app_secret>
export crw_github_client_id=<crw_oauth_app_id>
export crw_github_client_secret=<crw_oauth_app_secret>
export ocp_github_client_id=<ocp_oauth_app_id>
export ocp_github_client_secret=<ocp_oauth_app_secret>
export org_admin_pat=<pat token>
```

now you can source the file and populate the environment variables any time:

```shell
source ./secrets.sh
```

Run the following commands to populate the Kubernetes secrets with the previously generated values (this is fine for a demo, it might not be fine for a production environment):

```shell
oc new-project openshift-workspaces
oc create secret generic github-oauth-config --from-literal=id=${crw_github_client_id} --from-literal=secret=${crw_github_client_secret} -n openshift-workspaces
oc label secret github-oauth-config -n openshift-workspaces --overwrite=true app.kubernetes.io/part-of=che.eclipse.org app.kubernetes.io/component=oauth-scm-configuration
oc annotate secret github-oauth-config -n openshift-workspaces --overwrite=true che.eclipse.org/oauth-scm-server=github
oc create secret generic ocp-github-app-credentials -n openshift-config --from-literal=client_id=${ocp_github_client_id} --from-literal=clientSecret=${ocp_github_client_secret}
oc new-project backstage
oc create secret generic github-oauth-config -n backstage --from-literal=AUTH_GITHUB_CLIENT_ID=${backstage_github_client_id} --from-literal=AUTH_GITHUB_CLIENT_SECRET=${backstage_github_client_secret} --from-literal=GITHUB_TOKEN=${org_admin_pat} --from-literal=GITHUB_ORG=${github_organization}
```

To improve the demo experience and have some data pre-populated, you can optionally fork these repos to the new organization:

- `https://github.com/raf-backstage-demo/backstage`
- `https://github.com/raf-backstage-demo/software-templates`

The rest of the demo should be deployed by the gitops operator following the steps below.

## Deploy the gitops operator

```shell
oc apply -f ./argocd/operator.yaml
oc apply -f ./argocd/rbac.yaml
oc apply -f ./argocd/argocd.yaml
oc apply -f ./argocd/argo-root-application.yaml
```

this should be all to setup the demo.

## Scratch notes

https://gitlab-configuration-as-code.readthedocs.io/en/latest/faq.html

Kube service account for github, to be save as a org secret

oc new-project github-cicd
oc adm policy add-cluster-role-to-user cluster-admin -z default -n github-cicd
oc serviceaccounts get-token default -n github-cicd

kube svc account for backstage

```shell
oc create serviceaccount backstage -n default
oc adm policy add-cluster-role-to-user cluster-reader -z backstage -n default
oc serviceaccounts get-token backstage -n default
```
