# EKS Demo Cluster - Terraform + CI/CD

This directory contains the Infrastructure as Code and deployment configuration for a production-style EKS cluster with an application exposed via AWS Load Balancer.
The app is accessible at **https://dolev-demoapp.com**.

## Prerequisites

- AWS account with permissions to create EKS, VPC, IAM, etc.
- Terraform >= 1.6
- AWS CLI configured (`aws configure` or environment variables)
- `kubectl` and `helm` (optional, for manual verification)
- Docker Hub account (for the application image)

## Local Deployment

```bash
cd Q1

# Initialize
terraform init

# Plan
terraform plan -var="deploy_apps=false"

# Apply infrastructure only (first time)
terraform apply -var="deploy_apps=false"

# After the cluster and access entry exist, deploy the apps
terraform apply -var="deploy_apps=true" \
  -var="image_repository=dolev1234/node-demo-local" \
  -var="image_tag=latest"
```

### Important Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `deploy_apps` | `false` | Set to `true` to install ALB Controller + application |
| `image_repository` | `dolev1234/node-demo-local` | Docker image repository |
| `image_tag` | `latest` | Image tag (pipeline overrides with commit SHA) |
| `cluster_name` | `dolev-demo-cluster-v2` | EKS cluster name |

## CI/CD Pipeline 

The pipeline (`.github/workflows/pipline.yaml`) runs automatically on push to `main` when files under `Q1/` change.

### What the pipeline does

1. **Build & Push** – Builds the Docker image and pushes it to dockerhub
2. **Access Entry** – Ensures the CI user has admin access to the EKS cluster (`-refresh=false` to avoid race conditions)
3. **Clean pending Helm** – Removes stuck Helm operations from previous failed runs
4. **Terraform Apply** – Deploys/updates the ALB Controller, application, and Ingress
5. **Slack Notification** – Sends Slack notification for the docker build and the terraform outputs

### Required GitHub Secrets

| Secret | Description |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | Access key for the CI IAM user |
| `AWS_SECRET_ACCESS_KEY` | Secret key |
| `DOCKERHUB_USERNAME` | Docker Hub username |
| `DOCKERHUB_TOKEN` | Docker Hub access token |
| `SLACK_WEBHOOK` | Slack incoming webhook URL |



## Outputs

After a successful apply with `deploy_apps=true`:

```bash
terraform output alb_hostname
slack msg for the url (http://<url/domain>)
```

This is the public URL of the application (HTTPS).


