```sh
# Set environment variables
REGION="us-west-2"
CLUSTER_NAME="hc1"
SECRET_CREDS="raffa-aws"  # The credential name defined in step 2.
NAMESPACE="open-cluster-management"  # $SECRET_CREDS needs to exist in $NAMESPACE.

hypershift create cluster aws --name $CLUSTER_NAME --namespace $NAMESPACE --node-pool-replicas=3 --secret-creds $SECRET_CREDS --region $REGION
```