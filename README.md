# CodeAlpha DevOps Task 1 — CI/CD Pipeline using Azure

An automated CI/CD pipeline (Azure Pipelines) that builds a small Node.js web app into a Docker
image, pushes it to **Azure Container Registry (ACR)**, deploys it to **Azure App Service**
automatically, and runs a smoke test to help "monitor pipeline execution."

## What's inside
- **`app/`** — a minimal Express web app with a `/health` endpoint (used both by the pipeline's
  smoke test and by App Service's own container health checks).
- **`app/Dockerfile`** — containerizes the app.
- **`azure-pipelines.yml`** — the 3-stage pipeline: **Build** (build & push to ACR) → **Deploy**
  (deploy the new image to App Service) → **Verify** (curl `/health` and fail the pipeline if the
  app isn't responding, so a bad deploy gets caught immediately).
- **`provision-azure-resources.sh`** — an Azure CLI script that provisions everything the pipeline
  needs (resource group, ACR, App Service plan, Web App, registry credentials, log streaming) in
  one run, instead of clicking through the Azure Portal.

## Why this can't be "fully pre-built" for you
Azure Pipelines and Azure App Service are managed cloud services — they only exist once *you*
provision them under *your own* Azure subscription. There's no way to hand you a working pipeline
without your own Azure account. What's provided here is everything code-side: the app, the
Dockerfile, the pipeline definition, and a script that automates the Azure setup to a single
command — so the only manual parts left are things that inherently require your own account
(logging into Azure, creating an Azure DevOps org/project, and authorizing the service connections).

## Setup — step by step

### 1. Get an Azure account
If you don't have one, [Azure Free Account](https://azure.microsoft.com/free/) gives students/new
users free credits — plenty for this task.

### 2. Provision the Azure resources
```bash
az login
chmod +x provision-azure-resources.sh
./provision-azure-resources.sh
```
This creates a resource group, an ACR, a Linux App Service plan, and a Web App, and prints out the
exact names it generated. **Copy those into `azure-pipelines.yml`** (the `variables:` block near
the top — `acrName`, `appServiceName`, `resourceGroup`).

### 3. Create an Azure DevOps project and push this repo
1. Go to [dev.azure.com](https://dev.azure.com), create an organization (if you don't have one) and
   a new **Project**.
2. Under **Repos**, either push this folder's code to the built-in Azure Repos git, or connect an
   external GitHub repo (Project Settings → Service connections lets Azure Pipelines read a GitHub
   repo too, if you'd rather keep everything on GitHub for your CodeAlpha submission).

### 4. Create the service connections
Azure Pipelines needs permission to act on your behalf:
1. **Project Settings → Service connections → New service connection → Azure Resource Manager** —
   authorize it against your subscription. Name it to match `azureSubscriptionServiceConnection` in
   `azure-pipelines.yml` (default: `codealpha-azure-connection`).
2. **New service connection → Docker Registry → Azure Container Registry** — pick the ACR you just
   created. Name it to match `acrServiceConnection` (default: `codealpha-acr-connection`).

### 5. Create the pipeline
**Pipelines → New Pipeline** → point it at your repo → Azure DevOps will detect
`azure-pipelines.yml` automatically → **Run**.

### 6. Watch it run
You'll see the three stages (Build, Deploy, Verify) execute in order in the Azure DevOps UI. Once
it's green, visit:
```
https://<your-app-service-name>.azurewebsites.net
```

### 7. Monitor it going forward
- **Pipeline runs**: the Pipelines tab in Azure DevOps shows history, logs, and pass/fail per stage
  — that satisfies "monitor pipeline to ensure smooth execution."
- **App logs**: `az webapp log tail --name <app-name> --resource-group codealpha-devops-rg`
- For deeper monitoring, enable **Application Insights** on the Web App (Azure Portal → your Web
  App → Application Insights → Turn on) to get request rates, failures, and response times.

## Project structure
```
app/
  server.js            The demo app
  package.json
  Dockerfile
azure-pipelines.yml     The 3-stage CI/CD pipeline definition
provision-azure-resources.sh   One-shot Azure CLI provisioning script
```
