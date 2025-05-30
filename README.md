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

az ad sp create-for-rbac \
  --name "github-deploy-aks-agic" \
  --role "Contributor" \
  --scopes /subscriptions/$SUBSCRIPTION_ID \
  --sdk-auth


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

above example Output will be displayed on terminal (azure cli) after service principal creation command and copy the JSON output and follow below step.

## Add to GitHub Repository Secrets
Go to your GitHub repo.

Navigate to: Settings > Secrets and variables > Actions > New repository secret.

Name it: AZURE_CREDENTIALS or your desired variable name

Paste the entire JSON output from the command above.

Go to GitHub repo → Settings → Secrets and Variables → Actions:


Add:

AZURE_CREDENTIALS: JSON from az ad sp create-for-rbac ... --sdk-auth

(Optional) ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_SUBSCRIPTION_ID, ARM_TENANT_ID for Terraform workflows
