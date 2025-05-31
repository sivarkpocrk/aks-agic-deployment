# AKS + Application Gateway Ingress (AGIC) Deployment

This repo automates the deployment of an AKS cluster integrated with Azure Application Gateway (AGIC) and a sample HTTP Echo app.

## 📁 Structure
- `azure/terraform/`: Infrastructure using Terraform
- `azure/scripts/`: Azure CLI script
- `k8s/`: Kubernetes app manifests
- `.github/workflows/`: CI/CD automation

## 🚀 Deployment Methods
1. **Azure CLI**: `bash azure/scripts/deploy.sh`
2. **Terraform**: `cd azure/terraform && terraform apply`
3. **GitHub Actions**: Auto deploy on `git push`

## 🔐 Secrets
Add `AZURE_CREDENTIALS` to your repo secrets for GitHub Actions.

## 🌐 Result
- AKS Cluster in Azure
- Application Gateway with Ingress Controller
- HTTP Echo service exposed via public IP


# Create folder and init
mkdir aks-agic-deployment && cd aks-agic-deployment
git init

# Add remote (if using GitHub)
git remote add origin https://github.com/yourusername/aks-agic-deployment.git

# Add files
mkdir -p .github/workflows azure/{scripts,terraform} k8s
touch README.md .gitignore LICENSE

# Stage and commit
git add .
git commit -m "Initial AKS + AGIC setup with Terraform and GitHub Actions"

# Push
git push -u origin main

# Step to add secrets

SUBSCRIPTION_ID=$(az account show --query id -o tsv)

- `az ad sp create-for-rbac \
  --name "github-deploy-aks-agic" \
  --role "Contributor" \
  --scopes /subscriptions/$SUBSCRIPTION_ID \
  --sdk-auth`


{
  "clientId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "clientSecret": "xxxxxxxxxxxxxxxx",
  "subscriptionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}

- above example Output will be displayed on terminal (azure cli) after service principal creation command and copy the JSON output and follow below step.

## Add to GitHub Repository Secrets
- `Go to your GitHub repo.`

- `Navigate to: Settings > Secrets and variables > Actions > New repository secret.`

- `Name it: AZURE_CREDENTIALS or your desired variable name`

- `Paste the entire JSON output from the command above.`

- `Go to GitHub repo → Settings → Secrets and Variables → Actions:`

- Add:

- AZURE_CREDENTIALS: JSON from az ad sp create-for-rbac ... --sdk-auth

- (Optional) ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_SUBSCRIPTION_ID, ARM_TENANT_ID for Terraform workflows

## Use it in your role assignment check

- SP_APP_ID=$(az ad sp list --display-name github-deploy-aks-agic --query "[0].appId" -o tsv)
- az role assignment list --assignee $SP_APP_ID --output table


# Command history of Trouble shooting


    1  az aks create   --resource-group rg-k8s-api   --name aks-k8s-api   --node-count 2   --enable-managed-identity   --node-vm-size Standard_B2ms   --network-plugin azure   --vnet-subnet-id $(az network vnet subnet show \
    2          --resource-group rg-k8s-api \
    3          --vnet-name vnet-k8s \
    4          --name aks-subnet \
    5          --query id -o tsv)   --service-cidr 10.1.0.0/16   --dns-service-ip 10.1.0.10   --docker-bridge-address 172.17.0.1/16   --generate-ssh-keys
    6  az aks enable-addons   --resource-group rg-k8s-api   --name aks-k8s-api   --addons ingress-appgw   --appgw-id $(az network application-gateway show --resource-group rg-k8s-api --name appgw-k8s --query id -o tsv)
    7  clear
    8  az aks get-credentials   --resource-group rg-k8s-api   --name aks-k8s-api
    9  kubectl apply -f deployment.yaml
   10  kubectl apply -f service.yaml
   11  kubectl apply -f ingress.yaml
   12  az network public-ip show   --name appgw-ip   --resource-group rg-k8s-api   --query ipAddress -o tsv
   13  az account show --query id -o tsv
   14  SUBSCRIPTION_ID=$(az account show --query id -o tsv)
   15  az ad sp create-for-rbac   --name "github-deploy-aks-agic"   --role "Contributor"   --scopes /subscriptions/$SUBSCRIPTION_ID   --sdk-auth
   16  history
   17  clear
   18  az quota list --location westeurope --resource-type standard --output table
   19  az extension add --name quota
   20  az quota list --location westeurope --resource-type standard --output table
   21  SUBSCRIPTION_ID=$(az account show --query id -o tsv)
   22  az quota list   --scope /subscriptions/$SUBSCRIPTION_ID/providers/Microsoft.Compute/locations/westeurope   --output table
   23  az provider register --namespace Microsoft.Quota
   24  az provider show --namespace Microsoft.Quota --query "registrationState" -o tsv
   25  az quota list   --scope /subscriptions/$SUBSCRIPTION_ID/providers/Microsoft.Compute/locations/westeurope   --output table
   26  clear
   27  az quota show   --scope /subscriptions/$SUBSCRIPTION_ID/providers/Microsoft.Compute/locations/westeurope   --name cores   --output table
   28  az quota list   --scope /subscriptions/$SUBSCRIPTION_ID/providers/Microsoft.Compute/locations/westeurope  --name cores --output table
   29  echo SUBSCRIPTION_ID
   30  echo 4SUBSCRIPTION_ID
   31  echo $SUBSCRIPTION_ID
   32  for QUOTA in cores virtualMachines standardDSv3Family PremiumDiskCount; do   echo "=== $QUOTA ===";   az quota show     --scope /subscriptions/$SUBSCRIPTION_ID/providers/Microsoft.Compute/locations/westeurope     --name $QUOTA     --output table; done
   33  az quota show   --resource-name cores   --scope /subscriptions/$SUBSCRIPTION_ID/providers/Microsoft.Compute/locations/westeurope   --output table
   34  az quota show   --resource-name cores   --scope /subscriptions/$SUBSCRIPTION_ID/providers/Microsoft.Compute/locations/westeurope   --output json
   35  az quota show   --resource-name cores   --scope /subscriptions/$SUBSCRIPTION_ID/providers/Microsoft.Compute/locations/westeurope   --query "properties.{Limit:limit, Usage:currentValue, Unit:unit}"   --output table
   36  az quota show   --resource-name cores   --scope /subscriptions/$SUBSCRIPTION_ID/providers/Microsoft.Compute/locations/eastus   --output json
   37  az vm list-usage --location westeurope --output table
   38  az vm list-usage --location uksouth --output table

