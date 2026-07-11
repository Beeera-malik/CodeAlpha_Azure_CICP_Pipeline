#!/usr/bin/env bash
# Provisions the Azure resources this pipeline deploys to:
#   Resource Group -> Container Registry (ACR) -> App Service Plan (Linux) -> Web App (container-based)
#
# Requires: Azure CLI installed and logged in (`az login`).
# Usage: ./provision-azure-resources.sh

set -euo pipefail

RESOURCE_GROUP="codealpha-devops-rg"
LOCATION="eastus"
ACR_NAME="codealphaacr$RANDOM"     # ACR names must be globally unique
APP_SERVICE_PLAN="codealpha-cicd-plan"
WEB_APP_NAME="codealpha-cicd-demo-app-$RANDOM"

echo "Using:"
echo "  Resource group : $RESOURCE_GROUP"
echo "  Location       : $LOCATION"
echo "  ACR name       : $ACR_NAME"
echo "  App Service    : $WEB_APP_NAME"
echo ""

echo "==> Creating resource group..."
az group create --name "$RESOURCE_GROUP" --location "$LOCATION"

echo "==> Creating Azure Container Registry..."
az acr create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$ACR_NAME" \
  --sku Basic \
  --admin-enabled true

echo "==> Creating Linux App Service plan..."
az appservice plan create \
  --name "$APP_SERVICE_PLAN" \
  --resource-group "$RESOURCE_GROUP" \
  --is-linux \
  --sku B1

echo "==> Creating the Web App (placeholder image; the pipeline will replace it on first deploy)..."
az webapp create \
  --resource-group "$RESOURCE_GROUP" \
  --plan "$APP_SERVICE_PLAN" \
  --name "$WEB_APP_NAME" \
  --deployment-container-image-name "mcr.microsoft.com/appsvc/staticsite:latest"

echo "==> Pointing the Web App at your ACR (so it can pull images after each deploy)..."
ACR_LOGIN_SERVER=$(az acr show --name "$ACR_NAME" --query loginServer -o tsv)
ACR_USERNAME=$(az acr credential show --name "$ACR_NAME" --query username -o tsv)
ACR_PASSWORD=$(az acr credential show --name "$ACR_NAME" --query passwords[0].value -o tsv)

az webapp config container set \
  --name "$WEB_APP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --docker-registry-server-url "https://$ACR_LOGIN_SERVER" \
  --docker-registry-server-user "$ACR_USERNAME" \
  --docker-registry-server-password "$ACR_PASSWORD"

echo "==> Enabling container/App Service logging (useful for the 'monitor pipeline' requirement)..."
az webapp log config \
  --name "$WEB_APP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --docker-container-logging filesystem

echo ""
echo "======================================================================"
echo "Done. Update azure-pipelines.yml with these values:"
echo "  acrName:        $ACR_NAME"
echo "  appServiceName: $WEB_APP_NAME"
echo "  resourceGroup:  $RESOURCE_GROUP"
echo ""
echo "App URL (until the pipeline deploys your real image): https://$WEB_APP_NAME.azurewebsites.net"
echo "Stream logs any time with:"
echo "  az webapp log tail --name $WEB_APP_NAME --resource-group $RESOURCE_GROUP"
echo "======================================================================"
