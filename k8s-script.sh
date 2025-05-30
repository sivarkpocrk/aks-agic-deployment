# Resource group
az group create -n rg-k8s-api --location westeurope

# Virtual network and subnets
az network vnet create \
  --resource-group rg-k8s-api \
  --name vnet-k8s \
  --address-prefix 10.0.0.0/16 \
  --subnet-name aks-subnet \
  --subnet-prefix 10.0.1.0/24

az network vnet subnet create \
  --resource-group rg-k8s-api \
  --vnet-name vnet-k8s \
  --name appgw-subnet \
  --address-prefix 10.0.2.0/24

# Public IP for App Gateway
az network public-ip create \
  --resource-group rg-k8s-api \
  --name appgw-ip \
  --sku Standard

# Create App Gateway
az network application-gateway create \
  --name appgw-k8s \
  --location westeurope \
  --resource-group rg-k8s-api \
  --sku Standard_v2 \
  --capacity 2 \
  --vnet-name vnet-k8s \
  --subnet appgw-subnet \
  --public-ip-address appgw-ip \
  --frontend-port 80 \
  --http-settings-port 80 \
  --http-settings-protocol Http \
  --http-settings-cookie-based-affinity Disabled

az network application-gateway create \
  --name appgw-k8s \
  --location westeurope \
  --resource-group rg-k8s-api \
  --sku Standard_v2 \
  --capacity 2 \
  --vnet-name vnet-k8s \
  --subnet appgw-subnet \
  --public-ip-address appgw-ip \
  --no-wait \
  --disable-rule-creation true

az deployment group create \
  --name deploy-appgw-min \
  --resource-group rg-k8s-api \
  --template-file appgw-template.json


az aks enable-addons \
  --resource-group rg-k8s-api \
  --name aks-k8s-api \
  --addons ingress-appgw \
  --appgw-id $(az network application-gateway show -g rg-k8s-api -n appgw-k8s --query id -o tsv)



# Add Backend Pool
az network application-gateway address-pool create \
  --gateway-name appgw-k8s \
  --resource-group rg-k8s-api \
  --name backend-pool \
  --servers 10.0.1.4 10.0.1.5   # Example IPs of backend pods (or use FQDN)

# Step 3: Add HTTP Settings
az network application-gateway http-settings create \
  --gateway-name appgw-k8s \
  --resource-group rg-k8s-api \
  --name appGatewayBackendHttpSettings \
  --port 80 \
  --protocol Http \
  --cookie-based-affinity Disabled

# Step 4: Add Frontend Listener
az network application-gateway frontend-port create \
  --gateway-name appgw-k8s \
  --resource-group rg-k8s-api \
  --name frontendPort \
  --port 80

az network application-gateway http-listener create \
  --gateway-name appgw-k8s \
  --resource-group rg-k8s-api \
  --name appGatewayHttpListener \
  --frontend-port frontendPort \
  --frontend-ip appGatewayFrontendIP


# Step 5: Add Request Routing Rule with Priority

az network application-gateway rule create \
  --gateway-name appgw-k8s \
  --resource-group rg-k8s-api \
  --name rule1 \
  --rule-type Basic \
  --http-listener appGatewayHttpListener \
  --backend-address-pool backend-pool \
  --backend-http-settings appGatewayBackendHttpSettings \
  --priority 100


# Updated AKS Create Command
az aks create \
  --resource-group rg-k8s-api \
  --name aks-k8s-api \
  --node-count 2 \
  --enable-managed-identity \
  --node-vm-size Standard_B2ms \
  --network-plugin azure \
  --vnet-subnet-id $(az network vnet subnet show \
        --resource-group rg-k8s-api \
        --vnet-name vnet-k8s \
        --name aks-subnet \
        --query id -o tsv) \
  --service-cidr 10.1.0.0/16 \
  --dns-service-ip 10.1.0.10 \
  --docker-bridge-address 172.17.0.1/16 \
  --generate-ssh-keys

  # Enable Application Gateway Ingress Controller (AGIC)
  az aks enable-addons \
  --resource-group rg-k8s-api \
  --name aks-k8s-api \
  --addons ingress-appgw \
  --appgw-id $(az network application-gateway show --resource-group rg-k8s-api --name appgw-k8s --query id -o tsv)

