#!/bin/bash

# Variables
RG="rg-k8s-api-example-rg"
# LOCATION="westeurope"
LOCATION="uksouth"
VNET_NAME="vnet-k8s-test"
AKS_SUBNET="aks-subnet-test"
APPGW_SUBNET="appgw-subnet-test"
APPGW_NAME="appgw-k8s-test"
AKS_NAME="aks-k8s-api-test"
PUBLIC_IP="appgw-ip-test"

# Create RG and Network
az group create --name $RG --location $LOCATION

az network vnet create \
  --resource-group $RG \
  --name $VNET_NAME \
  --address-prefixes 10.0.0.0/8 \
  --subnet-name $AKS_SUBNET \
  --subnet-prefix 10.0.1.0/24

az network vnet subnet create \
  --resource-group $RG \
  --vnet-name $VNET_NAME \
  --name $APPGW_SUBNET \
  --address-prefix 10.0.2.0/24

az network public-ip create \
  --resource-group $RG \
  --name $PUBLIC_IP \
  --sku Standard


# Deploy App Gateway via Bicep/ARM or manual script (simplified here)

# az deployment group create \
#   --name deploy-appgw \
#   --resource-group $RG \
#   --template-file azure/arm/appgw-template.json \
#   --parameters @azure/arm/appgw-template-test-parm.json

  # --resource-group rg-k8s-api-example-rg \
  # --template-file appgw-template-test.json \
  # --parameters @appgw-template-test-parm.json

# Suggest to use validated template if needed

az deployment group create \
  --resource-group $RG \
  --template-file azure/arm/appgw-test.bicep \
  --parameters \
    appGatewayName=$APPGW_NAME \
    vnetName=$VNET_NAME \
    subnetName=$APPGW_SUBNET \
    publicIpName=$PUBLIC_IP

    # appGatewayName=appgw-k8s-test \
    # vnetName=vnet-k8s-test \
    # subnetName=appgw-subnet-test \
    # publicIpName=appgw-ip-test


# Create AKS
# SUBNET_ID=$(az network vnet subnet show --resource-group $RG --vnet-name $VNET_NAME --name $AKS_SUBNET --query id -o tsv)

echo "Checking values:"
echo "RG=$RG"
echo "VNET_NAME=$VNET_NAME"
echo "AKS_SUBNET=$AKS_SUBNET"

while true; do
  SUBNET_ID=$(az network vnet subnet show --resource-group $RG --vnet-name $VNET_NAME --name $AKS_SUBNET --query id -o tsv 2>/dev/null)
  if [[ -n "$SUBNET_ID" ]]; then
    echo "Subnet found: $SUBNET_ID"
    break
  else
    echo "Waiting for subnet to be available..."
    sleep 5
  fi
done



az aks create \
  --resource-group $RG \
  --name $AKS_NAME \
  --node-count 2 \
  --enable-managed-identity \
  --node-vm-size Standard_B2ms \
  --network-plugin azure \
  --vnet-subnet-id $SUBNET_ID \
  --service-cidr 10.1.0.0/16 \
  --dns-service-ip 10.1.0.10 \
  --docker-bridge-address 172.17.0.1/16 \
  --generate-ssh-keys

# Get credentials
az aks get-credentials --resource-group $RG --name $AKS_NAME

# Enable AGIC
APPGW_ID=$(az network application-gateway show --resource-group $RG --name $APPGW_NAME --query id -o tsv)

# Get AKS managed identity used by AGIC
AGIC_PRINCIPAL_ID=$(az aks show --resource-group $RG --name $AKS_NAME --query "identity.principalId" -o tsv)

SUB_ID=$(az account show --query id -o tsv)

# Assign RBAC roles for AGIC
az role assignment create --assignee $AGIC_PRINCIPAL_ID --role "Reader" --scope "/subscriptions/$SUB_ID/resourceGroups/$RG"
az role assignment create --assignee $AGIC_PRINCIPAL_ID --role "Contributor" --scope "$APPGW_ID"
az role assignment create --assignee $AGIC_PRINCIPAL_ID --role "Network Contributor" --scope "/subscriptions/$SUB_ID/resourceGroups/$RG/providers/Microsoft.Network/virtualNetworks/$VNET_NAME/subnets/$APPGW_SUBNET"

# Wait for role propagation
echo "Waiting for RBAC roles to propagate..."
sleep 30

az aks enable-addons \
  --resource-group $RG \
  --name $AKS_NAME \
  --addons ingress-appgw \
  --appgw-id $APPGW_ID

echo "Waiting for ingress-appgw pod to be created and ready..."

while true; do
  POD_STATUS=$(kubectl get pods -n kube-system -l app=ingress-appgw -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
  if [[ "$POD_STATUS" == "Running" ]]; then
    echo "AGIC pod is running."
    break
  else
    echo "Waiting for AGIC pod... current status: $POD_STATUS"
    sleep 10
  fi
done


# # Get AKS Managed Identity client ID

# SUB_ID=$(az account show --query id -o tsv)


# IDENTITY_CLIENT_ID=$(az aks show \
#   --resource-group $RG \
#   --name $AKS_NAME \
#   --query "identityProfile.kubeletidentity.clientId" -o tsv)

# echo "Waiting for RBAC roles to propagate..."
# sleep 30

# # Get the AKS MI object ID for AGIC (not kubelet, but AKS MSI)
# AGIC_PRINCIPAL_ID=$(az aks show \
#   --resource-group $RG \
#   --name $AKS_NAME \
#   --query "identity.principalId" -o tsv)

# echo "Waiting for RBAC roles to propagate...az role assignment create"
# sleep 30


# # Assign required roles
# az role assignment create \
#   --assignee $AGIC_PRINCIPAL_ID \
#   --role "Reader" \
#   --scope "/subscriptions/$SUB_ID/resourceGroups/$RG"

# echo "Waiting for RBAC roles to propagate...role assignment create"
# sleep 30

# az role assignment create \
#   --assignee $AGIC_PRINCIPAL_ID \
#   --role "Contributor" \
#   --scope $(az network application-gateway show --resource-group $RG --name $APPGW_NAME --query id -o tsv)

# echo "Waiting for RBAC roles to propagate...az role assignment create"
# sleep 30


# az role assignment create \
#   --assignee $AGIC_PRINCIPAL_ID \
#   --role "Network Contributor" \
#   --scope "/subscriptions/$SUB_ID/resourceGroups/$RG/providers/Microsoft.Network/virtualNetworks/$VNET_NAME/subnets/$APPGW_SUBNET"

# echo "before kibectl Waiting for RBAC roles to propagate..."
# sleep 30

if [[ ! -f k8s/deployment.yaml || ! -f k8s/service.yaml || ! -f k8s/ingress.yaml ]]; then
  echo "Error: One or more K8s YAML files missing in 'k8s/' directory."
  exit 1
fi

# Deploy K8s objects
# kubectl apply -f k8s/deployment.yaml
# kubectl apply -f k8s/service.yaml
# kubectl apply -f k8s/ingress.yaml

# Wait for external IP
# echo "Waiting for external IP assignment..."
# while true; do
#  IP=$(kubectl get ingress --all-namespaces -o jsonpath="{.items[0].status.loadBalancer.ingress[0].ip}" 2>/dev/null || true)
#  if [[ -n "$IP" ]]; then
#    echo "Application Gateway ingress is available at: http://$IP"
#    break
#  else
#    echo "Waiting for ingress IP..."
#    sleep 10
#  fi
#done
