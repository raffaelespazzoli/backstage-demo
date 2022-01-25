# backstage-demo

TL,DR, if you want to just setup the demo go to [here](#manual-preparation)
This demo is intended to show what a good developer experience might look like when developing applications to be deployed on OpenShift and the eco-system of tools that come with it.
The developer experience is divided in four pillars which are tightly interconnected but that we are going to examine separately.

1. the onboarding experience.
2. the coding time.
3. the build time.
4. the run time.

The objective of this demo is to explore how we can get a better and better experience while at the same time maintaining the following requirements:

1. Security. There is tension between making everything self-serviced and everything secure. When these two requirements come to a odd, security should win.
2. Scalability. whether we are supporting a team of developers with a few software components or hundreds of teams and thousands of components the cost should be the same. To do so we deploy everything via gitops and we automate all of the configuration/maintenance operations.

## Onboarding time

The onboarding time is the first time a developer experience the platform that comprise all of the tools. Onboarding should be as seamless as possible. Right now the onboarding experience is the following:

1. user on-boarding. A user must be invited to the github organization. This is equivalent to HR onboarding an employee into the enterprise IDP.
2. Application onboarding. An application is declared to exist and belong to a team. This application is given a set of namespace for its SDLC. This process is not defined yet.
3. Component onboarding. A software component which resides in a repo is onboarded to the system. It will be pre-configured to work with Code ready workspace and to be deployed by the pipelines to the previously defined namespace. This happens via the scaffolder feature of Backstage

## Code time

The purpose of the coding time experience is to provide a comfortable environment for developers to code and to run their inner loop. Ideally setting up the workspace should be immediate and the inner loop should be very fast (no more than ~30 seconds) while at the same time running the software components in an environment that is as close as possible as to what production will be.
In this demo the coding is done in Code Ready Workspaces. Each developer gets one or more workspaces for their software components which are easily accessible from Backstage.

## Build time

The purpose of the build time experience is to keep running pipeline simple for the developers while at the same time allowing for pipelines rich of functionalities. This can be done with the concept of pipeline as a service by which we mean that a central team manages one or more pipelines and developer *invoke* those pipelines as is they were a service, passing some parameters.
In this demo pipelines are implemented with github workflows and the concept of pipeline as a service is implemented using the shared workflow features.
When new components are created via scaffholder, also the pipeline is configured, so in theory a component is ready to be deployed to production right away after being created.

## Runtime

The runtime for the demo is OpenShift. The concept of a good runtime experience for a developer is that any piece of infrastructure needed to run the application should be self serviceable, possibly via manifests that will be deployed to OpenShift together with the rest of the application manifests. This includes also piece of infrastructure external to Openshift.
In this demo we have several operator that keep the configuration internal to OpenShift tidy and scale to any number of teams being ondoarded (permissions, quotas, etc). There are no example of external configuration at the moment.

For the future we plan to add monitoring to the runtime experience.

## Manual preparation

This demo is based on GitHub.
It requires some manual preparation steps for tasks that do not seem automate-able on GitHub (at least i was no able to automate them).

1. create a new organization or reuse an existing one.
2. create an Oauth app in this organization for backstage. The call back url should be `https://backstage.apps.${based_domain}/api/auth/github`
3. create an Oauth app in this organization for Code Ready Workspaces. The call back url should be `https://codeready-openshift-workspaces.apps.${based_domain}/auth/realms/codeready/broker/github/endpoint`
4. create an Oauth app in this organization for OpenShift. The call back url should be `https://oauth-openshift.apps.${based_domain}/oauth2callback/backstage-demo-github/`
5. create a Personal Access Token (PAT) with an account that is administrator to the chosen organization.
6. create a GitHub application in this organization for the github action runner controller following the instructions [here](https://github.com/actions-runner-controller/actions-runner-controller#deploying-using-github-app-authentication). Store the ssh key pem in a file called `github_action_runner_app.pem`, it will be ignored by git. The callback url should be `https://ghr.apps.${based_domain}`. The webhook secret is hardcoded to `ciao`.
7. create a GitHub Application for the group-sync-operator following the instructions [here](https://github.com/redhat-cop/group-sync-operator#as-a-github-app). Store the ssh key pem in a file called `group-sync-operator-app-key.pem`, it will be ignored by git.
8. create a PAT with package_read permissions on the entire organization. This will be used to pull images from all the namespaces.
9. create a PAT with package_write/read permissions on the entire organization. This will be used to push images from the build namespaces.

Create a client secret for each of the OAuth apps.

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
export action_runner_github_app_id=<application_id_for_action_runner>
export action_runner_github_app_installation_id=<application_installation_id_for_action_runner>
export action_runner_github_app_private_key_file_path=./github_action_runner_app.pem
export group_sync_github_app_id=<application_id_for_group_sync-operator>
export group_sync_operator_github_app_key_file_path=./group-sync-operator-app-key.pem
export package_puller_pat=<pat_token>
export package_pusher_pat=<pat_token>
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
oc create secret generic github-credentials -n backstage --from-literal=AUTH_GITHUB_CLIENT_ID=${backstage_github_client_id} --from-literal=AUTH_GITHUB_CLIENT_SECRET=${backstage_github_client_secret} --from-literal=GITHUB_TOKEN=${org_admin_pat} --from-literal=GITHUB_ORG=${github_organization}
oc new-project actions-runner-system
oc create secret generic controller-manager -n actions-runner-system --from-literal=github_app_id=${action_runner_github_app_id} --from-literal=github_app_installation_id=${action_runner_github_app_installation_id} --from-file=github_app_private_key=${action_runner_github_app_private_key_file_path}
oc new-project group-sync-operator
oc create secret generic github-group-sync -n group-sync-operator --from-literal=appId=${group_sync_github_app_id} --from-file=privateKey=${group_sync_operator_github_app_key_file_path}
oc create secret docker-registry ghcr-puller --docker-server=ghcr.io --docker-username=org_puller --docker-password=${package_puller_pat} --docker-email=org_puller@example.com -n openshift-config
oc create secret docker-registry ghcr-pusher --docker-server=ghcr.io --docker-username=org_pusher --docker-password=${package_pusher_pat} --docker-email=org_pusher@example.com -n openshift-config
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

This should be all to setup the demo.

Start enjoying the demo from here `https://backstage.apps.${based_domain}`.

## Notes

at the moment is still unclear what creates namespaces. regardless of that, namespace annotation are considered trusted and several security features revolve around them. These are the well known annotations:

- `app` : name of the app deployed to this namespace. This is used by the github runner to pick jobs from any component related to this app. For this to be secure, this piece of information needs to be trusted on the github workflow definition side.
- `team`: name of the team who owns this namespace (it will be considered an OCP group and given edit rights).
- `build-namespace`: the name of the namespace in which the pipeline which deploys to this namespace runs. In the build-namespace a github runner is deployed with edit permissions.
- `size`: determines the quota given to the namespace. Allowed values `small`, `medium`, `large`.
- `environment`: the purpose of the namespace. If environment equals build, an action runner for that app will be deployed. Other special behaviors related to environment might added in the future.



