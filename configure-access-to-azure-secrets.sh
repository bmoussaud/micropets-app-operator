CLUSTER_NAME=$1
KEY_VAULT=$2
KEY_VAULT_RG=$3
set -x 
KUBELET_IDENTITY_OBJECT_ID=$(az aks show --resource-group ${CLUSTER_NAME}   --name ${CLUSTER_NAME}   --query 'identityProfile.kubeletidentity.objectId' -o tsv)
echo ${KUBELET_IDENTITY_OBJECT_ID}
az keyvault set-policy --name ${KEY_VAULT} --resource-group  ${KEY_VAULT_RG}  --object-id "${KUBELET_IDENTITY_OBJECT_ID}" --certificate-permissions get --secret-permissions get