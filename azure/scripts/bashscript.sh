az ad sp create-for-rbac --name "gh-actions-aks" --sdk-auth --role contributor \
  --scopes /subscriptions/<sub-id>


# Add your AZURE_CREDENTIALS secret to GitHub as a JSON output of the above command
