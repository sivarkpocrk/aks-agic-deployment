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
SUBNET_ID=$(az network vnet subnet show --resource-group $RG --vnet-name $VNET_NAME --name $AKS_SUBNET --query id -o tsv)

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

az aks enable-addons \
  --resource-group $RG \
  --name $AKS_NAME \
  --addons ingress-appgw \
  --appgw-id $APPGW_ID

# Deploy K8s objects
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml

