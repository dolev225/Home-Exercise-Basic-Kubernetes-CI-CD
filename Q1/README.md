# EKS Demo Cluster - Terraform + CI/CD

This directory contains the Infrastructure as Code and deployment configuration for a production-style EKS cluster with an application exposed via AWS Load Balancer.

## Architecture Overview

```
Internet
   │
   ▼
[ALB] ←── Ingress (ALB Controller)
   │
   ▼
[EKS Cluster]
   ├── Managed Node Group (private subnets)
   └── AWS Load Balancer Controller (IRSA)

[VPC]
   ├── Public subnets  → Internet Gateway + ALB
   └── Private subnets → NAT Gateway (single, cost-optimized for demo)
```

### Key Design Decisions

| Decision | Reason |
|----------|--------|
| **Single NAT Gateway** | Cost optimization for a demo/dev environment. In production use one NAT per AZ. |
| **Public EKS endpoint** (`0.0.0.0/0`) | Simplifies CI/CD and local access. Restrict to your IP/CIDR in production. |
| **VPC Flow Logs** | Best practice for network visibility and troubleshooting. |
| **IRSA for ALB Controller** | Secure, temporary credentials instead of long-lived keys. |
| **Access Entries** | Modern EKS authentication (instead of aws-auth ConfigMap). |

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

## CI/CD Pipeline (GitHub Actions)

The pipeline (`.github/workflows/pipline.yaml`) runs automatically on push to `main` when files under `Q1/` change.

### What the pipeline does

1. **Build & Push** – Builds the Docker image and pushes it to `dolev1234/node-demo-local:<commit-sha>`
2. **Access Entry** – Ensures the CI user has admin access to the EKS cluster (`-refresh=false` to avoid race conditions)
3. **Clean pending Helm** – Removes stuck Helm operations from previous failed runs
4. **Terraform Apply** – Deploys/updates the ALB Controller, application, and Ingress
5. **Slack Notification** – Sends the ALB hostname to Slack

### Required GitHub Secrets

| Secret | Description |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | Access key for the CI IAM user |
| `AWS_SECRET_ACCESS_KEY` | Secret key |
| `DOCKERHUB_USERNAME` | Docker Hub username |
| `DOCKERHUB_TOKEN` | Docker Hub access token |
| `SLACK_WEBHOOK` | Slack incoming webhook URL |

## Connecting to the Cluster

```bash
aws eks update-kubeconfig --region us-east-1 --name dolev-demo-cluster-v2
kubectl get nodes
kubectl get pods -A
```

## Outputs

After a successful apply with `deploy_apps=true`:

```bash
terraform output alb_hostname
```

This is the public URL of the application (HTTP).

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `the server has asked for the client to provide credentials` | Run the targeted access entry apply first (see pipeline step). |
| `another operation is in progress` | The pipeline cleans this automatically. Manually: `kubectl delete secret -n default -l owner=helm,name=my-node-app,status=pending-upgrade` |
| `context deadline exceeded` | Image pull issue or pods not becoming Ready. Check `kubectl describe pod` and image name/tag. |
| ALB not created | Verify AWS Load Balancer Controller is running: `kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller` |

## Destroy

```bash
terraform destroy -var="deploy_apps=true"
```

> Note: Destroy the Helm releases / Ingress first if you encounter dependency issues, or set `deploy_apps=false` and apply before full destroy.
