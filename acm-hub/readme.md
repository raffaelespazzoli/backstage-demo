```sh

# Set environment variables
REGION="us-west-2"
BUCKET_NAME=raf-hcp-oidc
CLUSTER_NAME="hc1"
SECRET_CREDS="raffa-aws"  # The credential name defined in step 2.
NAMESPACE="open-cluster-management"  # $SECRET_CREDS needs to exist in $NAMESPACE.


aws s3api create-bucket --acl public-read --bucket $BUCKET_NAME --create-bucket-configuration LocationConstraint=$REGION --region $REGION
oc create secret generic hypershift-operator-oidc-provider-s3-credentials --from-file=credentials=$HOME/.aws/credentials --from-literal=bucket=$BUCKET_NAME --from-literal=region=$REGION -n local-cluster
hypershift create cluster aws --name $CLUSTER_NAME --namespace $NAMESPACE --node-pool-replicas=3 --secret-creds $SECRET_CREDS --region $REGION
```