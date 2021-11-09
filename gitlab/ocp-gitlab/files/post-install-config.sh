#!/bin/bash

set -o nounset
set -o errexit

#create the pat
export gitlab_hostname=$(oc get route gitlab -n gitlab-system -o jsonpath='{.spec.host}')
export expiration_date=$(date --date "`date` +365 days" "+%Y-%m-%d")
export root_password=$(oc get secret gitlab-gitlab-initial-root-password -n gitlab-system -o jsonpath='{.data.password}' | base64 -d)
echo "grant_type=password&username=root&password=${root_password}" > /tmp/data.txt
export access_token=$(curl --data "@/tmp/data.txt" --request POST "https://${gitlab_hostname}/oauth/token" | jq -r '.access_token')
export user_id=$(curl --request GET --header "Authorization: Bearer ${access_token}" "https://${gitlab_hostnamme}/api/v4/user" | jq -r .id)
export pat=$(curl --request POST --header "Authorization: Bearer ${access_token}" --data "name=root_pat" --data "expires_at=${expiration_date}" --data "scopes[]=api" "https://${gitlab_hostname}/api/v4/users/${user_id}/personal_access_tokens" | jq -r '.token')
export pat_b64=$(echo ${pat} | base64 -w0)
oc patch secret root-pat -p='{"data":{"pat": "'"${pat_b64}"'"}}' -n gitlab-system

#create users

for u in david andy; do
  echo "email=${u}@example.com&name=${u}&username=${u}&password=${u}${u}&skip_confirmation=true" > /tmp/data.txt
  curl --data "@/tmp/data.txt" --request POST --header "Authorization: Bearer ${access_token}" "https://${gitlab_hostname}/api/v4/users"
done  

for g in sales hr; do
  echo "name=${g}&path=${g}" > /tmp/data.txt
  curl --data "@/tmp/data.txt" --request POST --header "Authorization: Bearer ${access_token}" "https://${gitlab_hostname}/api/v4/groups"
done

export david_user_id=$(curl --request GET --header "Authorization: Bearer ${access_token}" "https://${gitlab_hostname}/api/v4/users?username=david" | jq -r .[0].id)
export andy_user_id=$(curl --request GET --header "Authorization: Bearer ${access_token}" "https://${gitlab_hostname}/api/v4/users?username=andy" | jq -r .[0].id)

export sales_group_id=$(curl --request GET --header "Authorization: Bearer ${access_token}" "https://${gitlab_hostname}/api/v4/groups" | jq '.[] | select(.name=="sales").id')
export hr_group_id=$(curl --request GET --header "Authorization: Bearer ${access_token}" "https://${gitlab_hostname}/api/v4/groups" | jq '.[] | select(.name=="hr").id')

# david in sales
curl --request POST --header "Authorization: Bearer ${access_token}" --data "user_id=${david_user_id}&access_level=30" "https://${gitlab_hostname}/api/v4/groups/${sales_group_id}/members"

# andy in hr
curl --request POST --header "Authorization: Bearer ${access_token}" --data "user_id=${andy_user_id}&access_level=30" "https://${gitlab_hostname}/api/v4/groups/${hr_group_id}/members"


# create application for OCP
export OCP_APP_RESPONSE=$(curl --request POST --header "Authorization: Bearer ${access_token}" --data "name=ocp&redirect_uri=https://oauth-openshift.apps.tmp-raffa.demo.red-chesterfield.com/oauth2callback/gitlab&scopes=profile read_user email openid" "https://${gitlab_hostname}/api/v4/applications")
oc patch secret ocp-gitlab-app-credentials -p='{"data":{"client_id": "'"$(echo ${OCP_APP_RESPONSE} | jq -r .application_id | base64 -w0)"'","clientSecret": "'"$(echo ${OCP_APP_RESPONSE} | jq -r .secret | base64 -w0)"'"}}' -n gitlab-system

# create application for backstage
export BACKSTAGE_APP_RESPONSE=$(curl --request POST --header "Authorization: Bearer ${access_token}" --data "name=backstage&redirect_uri=https://backstage.apps.tmp-raffa.demo.red-chesterfield.com/api/auth/gitlab/handler/frame&scopes=read_user" "https://${gitlab_hostname}/api/v4/applications")
oc patch secret backstage-gitlab-app-credentials -p='{"data":{"client_id": "'"$(echo ${BACKSTAGE_APP_RESPONSE} | jq -r .application_id | base64 -w0)"'","client_secret": "'"$(echo ${BACKSTAGE_APP_RESPONSE} | jq -r .secret | base64 -w0)"'"}}' -n gitlab-system

# create application for code ready workspaces
export CRW_APP_RESPONSE=$(curl --request POST --header "Authorization: Bearer ${access_token}" --data "name=CodeReadyWorkspaces&redirect_uri=https://keycloak-openshift-workspaces.tmp-raffa.demo.red-chesterfield.com/auth/realms/codeready/broker/gitlab/endpoint&scopes=read_user" "https://${gitlab_hostname}/api/v4/applications")
oc patch secret crw-gitlab-app-credentials -p='{"data":{"client_id": "'"$(echo ${CRW_APP_RESPONSE} | jq -r .application_id | base64 -w0)"'","client_secret": "'"$(echo ${CRW_APP_RESPONSE} | jq -r .secret | base64 -w0)"'"}}' -n gitlab-system